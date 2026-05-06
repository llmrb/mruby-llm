# frozen_string_literal: true

class LLM::Anthropic
  ##
  # @private
  module RequestAdapter

    ##
    # @param [Array<LLM::Message>] messages
    #  The messages to adapt
    # @return [Hash]
    def adapt(messages, mode: nil)
      payload = {messages: [], system: []}
      messages.each do |message|
        adapted = Completion.new(message).adapt
        next if adapted.nil?
        if system?(message)
          payload[:system].concat Array(adapted[:content])
        else
          payload[:messages] << adapted
        end
      end
      payload.delete(:system) if payload[:system].empty?
      payload
    end

    private

    ##
    # @param [Hash] params
    # @return [Hash]
    def adapt_tools(tools)
      return {} unless tools&.any?
      {tools: tools.map { _1.respond_to?(:adapt) ? _1.adapt(self) : _1 }}
    end

    def system?(message)
      if message.respond_to?(:system?)
        message.system?
      else
        Hash === message and message[:role].to_s == "system"
      end
    end
  end
end

LLM::Anthropic.include(LLM::Anthropic::RequestAdapter)
