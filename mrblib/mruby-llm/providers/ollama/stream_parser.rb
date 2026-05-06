# frozen_string_literal: true

class LLM::Ollama
  ##
  # @private
  class StreamParser
    ##
    # Returns the fully constructed response body
    # @return [Hash]
    attr_reader :body

    ##
    # @return [LLM::OpenAI::Chunk]
    def initialize(stream)
      @body = {}
      @stream = stream
      @can_push_content = stream.respond_to?(:<<)
    end

    ##
    # @param [Hash] chunk
    # @return [LLM::OpenAI::Chunk]
    def parse!(chunk)
      tap { merge!(chunk) }
    end

    ##
    # Frees internal parser state used during streaming.
    # @return [void]
    def free
    end

    private

    def merge!(chunk)
      chunk.each do |key, value|
        if key == "message"
          if @body[key]
            @body[key]["content"] << value["content"]
            @stream << value["content"] if @can_push_content
          else
            @body[key] = value
            @stream << value["content"] if @can_push_content
          end
        else
          @body[key] = value
        end
      end
    end
  end
end
