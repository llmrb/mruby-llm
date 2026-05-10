# frozen_string_literal: true

class LLM::Transport
  ##
  # @private
  class StreamDecoder
    ##
    # @return [Object]
    attr_reader :parser

    ##
    # @param [#parse!, #body] parser
    # @return [LLM::Transport::StreamDecoder]
    def initialize(parser)
      @buffer = +""
      @cursor = 0
      @data = []
      @parser = parser
    end

    ##
    # @param [String] chunk
    # @return [void]
    def <<(chunk)
      append_decoded(chunk)
    end

    ##
    # @return [Object]
    def body
      parser.body
    end

    ##
    # @return [void]
    def free
      @buffer.clear
      @cursor = 0
      @data.clear
      parser.free if parser.respond_to?(:free)
    end

    private

    def append_decoded(chunk)
      @buffer << chunk
      each_line { handle_line(_1) }
    end

    def handle_line(line)
      if line == "\n" || line == "\r\n"
        flush_sse_event
      elsif line.start_with?("data:")
        @data << field_value(line)
      elsif line.start_with?("event:", "id:", "retry:", ":")
      else
        decode!(strip_newline(line))
      end
    end

    def flush_sse_event
      return if @data.empty?
      decode!(@data.join("\n"))
      @data.clear
    end

    def field_value(line)
      value_start = line.getbyte(5) == 32 ? 6 : 5
      strip_newline(line.byteslice(value_start..))
    end

    def strip_newline(line)
      line = line.byteslice(0, line.bytesize - 1) if line.end_with?("\n")
      line = line.byteslice(0, line.bytesize - 1) if line.end_with?("\r")
      line
    end

    def decode!(payload)
      return if payload.empty? || payload == "[DONE]"
      chunk = LLM.json.load(payload)
      parser.parse!(chunk) if chunk
    rescue *LLM::JSON::Errors
    end

    def each_line
      while (newline = @buffer.index("\n", @cursor))
        line = @buffer[@cursor..newline]
        @cursor = newline + 1
        yield(line)
      end
      return if @cursor.zero?
      @buffer = @buffer[@cursor..] || +""
      @cursor = 0
    end

  end

  ##
  # @private
  class Curl::StreamDecoder < StreamDecoder
    ##
    # @param [#parse!, #body] parser
    # @return [LLM::Transport::Curl::StreamDecoder]
    def initialize(parser)
      super
      @raw = +""
      @chunk_bytes = nil
      @chunked = false
    end

    ##
    # @param [Boolean] value
    # @return [Boolean]
    attr_accessor :chunked

    ##
    # @param [String] chunk
    # @return [void]
    def <<(chunk)
      return if chunk.nil? || chunk.empty?
      chunked ? dechunk(chunk) : super
    end

    ##
    # @return [void]
    def free
      super
      @raw.clear
      @chunk_bytes = nil
    end

    private

    def dechunk(chunk)
      @raw << chunk
      loop do
        if @chunk_bytes.nil?
          line_end = @raw.index("\r\n")
          break unless line_end
          size = @raw.byteslice(0, line_end)
          @raw = @raw.byteslice(line_end + 2..) || +""
          semi = size.to_s.index(";")
          size = semi ? size.byteslice(0, semi) : size
          @chunk_bytes = size.to_i(16)
        end
        if @chunk_bytes.zero?
          trailer_end = @raw.index("\r\n\r\n")
          if trailer_end
            @raw = @raw.byteslice(trailer_end + 4..) || +""
            @chunk_bytes = nil
            next
          end
          break
        end
        break if @raw.bytesize < @chunk_bytes + 2
        append_decoded(@raw.byteslice(0, @chunk_bytes))
        @raw = @raw.byteslice(@chunk_bytes + 2..) || +""
        @chunk_bytes = nil
      end
    end
  end
end
