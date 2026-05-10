# frozen_string_literal: true

module LLM::OpenAI::RequestAdapter
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
    # Adapts the message for the OpenAI chat completions API
    # @return [Hash]
    def adapt
      catch(:abort) do
        if Hash === message
          {role: message[:role], content: adapt_content(message[:content])}
        elsif message.tool_call?
          {role: message.role, content: nil, tool_calls: message.extra[:original_tool_calls]}
        else
          adapt_message
        end
      end
    end

    private

    def adapt_message
      case content
      when Array
        adapt_array
      else
        {role: message.role, content: adapt_content(content)}
      end
    end

    def adapt_array
      if content.empty?
        nil
      elsif returns.any?
        returns.map { {role: "tool", tool_call_id: _1.id, content: LLM.json.dump(_1.value)} }
      else
        {role: message.role, content: content.flat_map { adapt_content(_1) }}
      end
    end

    def adapt_content(content)
      case content
      when LLM::Object
        adapt_object(content)
      when String
        [{type: :text, text: content.to_s}]
      when LLM::Response
        adapt_remote_file(content)
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
      when :image_url
        [{type: :image_url, image_url: {url: object.value}}]
      when :local_file
        adapt_local_file(object.value)
      when :remote_file
        adapt_remote_file(object.value)
      else
        prompt_error!(object)
      end
    end

    def adapt_local_file(file)
      if file.image?
        [{type: :image_url, image_url: {url: file.to_data_uri}}]
      else
        [{type: :file, file: {filename: file.basename, file_data: file.to_data_uri}}]
      end
    end

    def adapt_remote_file(file)
      if file.file?
        [{type: :file, file: {file_id: file.id}}]
      else
        prompt_error!(file)
      end
    end

    def prompt_error!(content)
      if LLM::Object === content
        raise LLM::PromptError, "The given LLM::Object with kind '#{content.kind}' is not " \
                                "supported by the OpenAI chat completions API."
      else
        raise LLM::PromptError, "The given object (an instance of #{content.class}) " \
                                "is not supported by the OpenAI chat completions API."
      end
    end

    def message = @message
    def content = message.content
    def returns = content.grep(LLM::Function::Return)
  end
end
