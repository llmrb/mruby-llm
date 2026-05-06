# frozen_string_literal: true

module LLM::DeepSeek::RequestAdapter
  ##
  # @private
  class Completion
    ##
    # @param [LLM::Message, Hash] message
    #  The message to format
    def initialize(message)
      @message = message
    end

    ##
    # Adapts the message for the DeepSeek chat completions API
    # @return [Hash]
    def adapt
      catch(:abort) do
        if Hash === message
          {role: message[:role], content: adapt_content(message[:content])}
        elsif message.tool_call?
          wrap(content: nil, tool_calls: message.extra[:original_tool_calls])
        else
          adapt_message
        end
      end
    end

    private

    def adapt_content(content)
      case content
      when LLM::Object
        adapt_object(content)
      when String
        [{type: :text, text: content.to_s}]
      when LLM::Message
        adapt_content(content.content)
      when LLM::Function::Return
        throw(:abort, {role: "tool", tool_call_id: content.id, content: LLM.json.dump(content.value)})
      else
        prompt_error!(content)
      end
    end

    def adapt_object(object)
      case object.kind
      when :image_url, :local_file, :remote_file
        prompt_error!(object)
      else
        prompt_error!(object)
      end
    end

    def adapt_message
      case content
      when Array
        adapt_array
      else
        wrap(content: adapt_content(content))
      end
    end

    def adapt_array
      if content.empty?
        nil
      elsif returns.any?
        returns.map { {role: "tool", tool_call_id: _1.id, content: LLM.json.dump(_1.value)} }
      else
        wrap(content: content.flat_map { adapt_content(_1) })
      end
    end

    def prompt_error!(object)
      if LLM::Object === object
        raise LLM::PromptError, "The given LLM::Object with kind '#{object.kind}' is not " \
                                "supported by the DeepSeek API"
      else
        raise LLM::PromptError, "The given object (an instance of #{object.class}) " \
                                "is not supported by the DeepSeek API"
      end
    end

    def wrap(content:, tool_calls: nil)
      {
        role: message.role,
        content:,
        tool_calls: tool_calls&.map { LLM::Object === _1 ? _1.to_h : _1 },
        reasoning_content: message.reasoning_content
      }.compact.then { preserve_nil_content(_1) }
    end

    def message = @message
    def content = message.content
    def returns = content.grep(LLM::Function::Return)

    def preserve_nil_content(hash)
      hash[:content] = content if content.nil?
      hash
    end
  end
end
