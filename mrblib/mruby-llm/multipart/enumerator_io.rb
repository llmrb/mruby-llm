# frozen_string_literal: true

class LLM::Multipart
  ##
  # @private
  # Wraps an Enumerator as an IO-like object for streaming bodies.
  class EnumeratorIO
    ##
    # @param [Enumerator] enum
    #  The enumerator yielding body chunks
    def initialize(enum)
      @enum = enum
      @buffer = +""
      @eof = false
    end

    ##
    # Reads bytes from the stream
    # @param [Integer, nil] length
    #  The number of bytes to read (all when nil)
    # @param [String] outbuf
    #  The buffer to fill
    # @return [String, nil]
    #  Returns the data read, or nil on EOF
    def read(length = nil, outbuf = +"")
      outbuf.clear
      if length.nil?
        read_all(outbuf)
      else
        read_chunk(length, outbuf)
      end
    end

    ##
    # Returns true when no more data is available
    # @return [Boolean]
    def eof?
      @eof && @buffer.empty?
    end

    ##
    # Raises when called, the stream is not rewindable
    # @raise [IOError]
    def rewind
      raise IOError, "stream is not rewindable"
    end

    private

    def read_all(outbuf)
      fill_buffer
      return nil if eof?
      outbuf << @buffer
      @buffer.clear
      while (chunk = next_chunk)
        outbuf << chunk
      end
      @eof = true
      outbuf
    end

    def read_chunk(length, outbuf)
      fill_buffer while @buffer.bytesize < length && !@eof
      return nil if eof?
      outbuf << @buffer.byteslice(0, length)
      @buffer = @buffer.byteslice(length..-1) || +""
      outbuf
    end

    def fill_buffer
      return if @eof
      chunk = next_chunk
      if chunk
        @buffer << chunk
      else
        @eof = true
      end
    end

    def next_chunk
      @enum.next
    rescue StopIteration
      nil
    end
  end
end
