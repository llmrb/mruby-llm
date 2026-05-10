# frozen_string_literal: true

class LLM::Anthropic
  module Utils
    ##
    # Normalizes Anthropic tool input to a Hash suitable for kwargs.
    # @param input [Hash, String, nil]
    # @return [Hash]
    def parse_tool_input(input)
      case input
      when Hash then input
      when String
        parsed = LLM.json.load(input)
        Hash === parsed ? parsed : {}
      when nil then {}
      else
        input.respond_to?(:to_h) ? input.to_h : {}
      end
    rescue *LLM::JSON::Errors
      {}
    end
  end
end

LLM::Anthropic.extend(LLM::Anthropic::Utils)
