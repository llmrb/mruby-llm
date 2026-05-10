# frozen_string_literal: true

module LLM::MCP::Transport
  class HTTP
    class EventHandler
      def initialize(&on_message)
        @on_message = on_message
        reset
      end

      def on_event(event, chunk = nil)
        @event = chunk ? event : event.value
      end

      def on_data(event, chunk = nil)
        @data << (chunk ? event : event.value).to_s
      end

      def on_chunk(event, chunk = nil)
        flush if (chunk || event&.chunk || event) == "\n"
      end

      private

      def flush
        return reset if @data.empty? && @event.nil?
        payload = @data.join("\n")
        reset
        return if payload.empty? || payload == "[DONE]"
        @on_message.call(LLM.json.load(payload))
      rescue *LLM::JSON::Errors
        reset
      end

      def reset
        @event = nil
        @data = []
      end
    end
  end
end
