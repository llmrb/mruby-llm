# frozen_string_literal: true

module LLM::Provider::Transport
  ##
  # @private
  class HTTP::StreamDecoder
    ##
    # @return [Object]
    attr_reader :parser

    ##
    # @param [#parse!, #body] parser
    # @return [LLM::Provider::Transport::HTTP::StreamDecoder]
    def initialize(parser)
      @buffer = +""
      @cursor = 0
      @data = []
      @raw = +""
      @chunk_bytes = nil
      @chunked = false
      @parser = parser
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
      chunked ? dechunk(chunk) : append_decoded(chunk)
    end

    def append_decoded(chunk)
      @buffer << chunk
      each_line { handle_line(_1) }
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
      @raw.clear
      @chunk_bytes = nil
      parser.free if parser.respond_to?(:free)
    end

    private

    ##
    # Decode raw HTTP chunked-transfer payloads into plain body bytes before
    # normal SSE line parsing continues.
    #
    # `mruby-curl` can yield body chunks with transfer framing still attached,
    # so streamed provider responses may arrive as:
    #
    # - chunk-size line
    # - chunk payload
    # - trailing CRLF
    #
    # This method keeps partial transfer state across callback invocations in
    # `@raw` and `@chunk_bytes`, emitting only fully decoded payload bytes to
    # {#append_decoded}.
    #
    # @param [String] chunk
    #  A raw body fragment from curl
    # @return [void]
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
end
