# frozen_string_literal: true

class LLM::Anthropic
  ##
  # @private
  module ResponseAdapter

    module_function

    ##
    # @param [LLM::Response, LLM::Transport::Response] res
    # @param [Symbol] type
    # @return [LLM::Response]
    def adapt(res, type:)
      res = (LLM::Response === res) ? res : LLM::Response.new(res)
      res.extend(select(type))
    end

    ##
    # @api private
    def select(type)
      case type
      when :completion then LLM::Anthropic::ResponseAdapter::Completion
      when :enumerable then LLM::Anthropic::ResponseAdapter::Enumerable
      when :file then LLM::Anthropic::ResponseAdapter::File
      when :models then LLM::Anthropic::ResponseAdapter::Models
      when :web_search then LLM::Anthropic::ResponseAdapter::WebSearch
      else
        raise ArgumentError, "Unknown response adapter type: #{type.inspect}"
      end
    end
  end
end
