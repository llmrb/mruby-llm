# frozen_string_literal: true

module LLM
  ##
  # @private
  class EventHandler
    ##
    # @param [#parse!] parser
    # @return [LLM::EventHandler]
    def initialize(parser)
      @parser = parser
    end

    ##
    # "data:" event callback
    # @param [LLM::EventStream::Event, String, nil] event
    # @param [String, nil] chunk
    # @return [void]
    def on_data(event, chunk = nil)
      value = chunk ? event : event.value
      return if value == "[DONE]"
      payload = LLM.json.load(value)
      return unless payload
      @parser.parse!(payload)
    rescue *LLM::JSON::Errors
    end

    ##
    # Callback for when *any* of chunk of data
    # is received, regardless of whether it has
    # a field name or not. Primarily for ollama,
    # which does emit Server-Sent Events (SSE).
    # @param [LLM::EventStream::Event, String, nil] event
    # @param [String, nil] chunk
    # @return [void]
    def on_chunk(event, chunk = nil)
      raw_chunk = chunk || event&.chunk || event
      return if raw_chunk == "[DONE]"
      payload = LLM.json.load(raw_chunk)
      return unless payload
      @parser.parse!(payload)
    rescue *LLM::JSON::Errors
    end

    ##
    # Returns a fully constructed response body
    # @return [LLM::Object]
    def body = @parser.body

    ##
    # Frees parser state after streaming completes.
    # @return [void]
    def free
      @parser.free
    end
  end
end
