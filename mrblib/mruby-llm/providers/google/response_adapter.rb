# frozen_string_literal: true

class LLM::Google
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
      when :completion then LLM::Google::ResponseAdapter::Completion
      when :embedding then LLM::Google::ResponseAdapter::Embedding
      when :file then LLM::Google::ResponseAdapter::File
      when :files then LLM::Google::ResponseAdapter::Files
      when :image then LLM::Google::ResponseAdapter::Image
      when :models then LLM::Google::ResponseAdapter::Models
      when :web_search then LLM::Google::ResponseAdapter::WebSearch
      else
        raise ArgumentError, "Unknown response adapter type: #{type.inspect}"
      end
    end
  end
end
