# frozen_string_literal: true

class LLM::DeepSeek
  ##
  # @private
  module RequestAdapter
    ##
    # @param [Array<LLM::Message>] messages
    #  The messages to adapt
    # @return [Array<Hash>]
    def adapt(messages, mode: nil)
      messages.filter_map do |message|
        Completion.new(message).adapt
      end
    end

    private

    ##
    # @param [Hash] params
    # @return [Hash]
    def adapt_tools(tools)
      (tools.nil? || tools.empty?) ? {} : {tools: tools.map { _1.adapt(self) }}
    end
  end
end

LLM::DeepSeek.include(LLM::DeepSeek::RequestAdapter)
