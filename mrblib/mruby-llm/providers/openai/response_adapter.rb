# frozen_string_literal: true

class LLM::OpenAI
  ##
  # @private
  module ResponseAdapter

    ##
    # @param [LLM::Response, LLM::Transport::Response] res
    # @param [Symbol] type
    # @return [LLM::Response]
    def self.adapt(res, type:)
      res = (LLM::Response === res) ? res : LLM::Response.new(res)
      adapter = select(type)
      res.extend(adapter)
    end

    ##
    # @api private
    def self.select(type)
      case type
      when :audio then LLM::OpenAI::ResponseAdapter::Audio
      when :completion then LLM::OpenAI::ResponseAdapter::Completion
      when :embedding then LLM::OpenAI::ResponseAdapter::Embedding
      when :enumerable then LLM::OpenAI::ResponseAdapter::Enumerable
      when :file then LLM::OpenAI::ResponseAdapter::File
      when :image then LLM::OpenAI::ResponseAdapter::Image
      when :moderations then LLM::OpenAI::ResponseAdapter::Moderations
      when :models then LLM::OpenAI::ResponseAdapter::Models
      when :responds then LLM::OpenAI::ResponseAdapter::Responds
      when :web_search then LLM::OpenAI::ResponseAdapter::WebSearch
      else
        raise ArgumentError, "Unknown response adapter type: #{type.inspect}"
      end
    end
  end
end
