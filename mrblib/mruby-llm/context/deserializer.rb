# frozen_string_literal: true

class LLM::Context
  ##
  # @api private
  module Deserializer
    ##
    # Restore a saved context state
    # @param [String, nil] path
    #  The path to a JSON file
    # @param [String, nil] string
    #  A raw JSON string
    # @param [Hash, nil] data
    #  A parsed context payload
    # @raise [SystemCallError]
    #  Might raise a number of SystemCallError subclasses
    # @return [LLM::Context]
    def deserialize(path: nil, string: nil, data: nil)
      ctx = if data
        data
      elsif path.nil? and string.nil?
        raise ArgumentError, "a path, string, or data payload is required"
      elsif path
        ::File.open(path, "r") { LLM.json.load(_1.read) }
      else
        LLM.json.load(string)
      end
      @messages.concat [*ctx["messages"]].map { deserialize_message(_1) }
      @compacted = !!ctx["compacted"]
      self
    end
    alias_method :restore, :deserialize

    ##
    # @param [Hash] payload
    # @return [LLM::Message]
    def deserialize_message(payload)
      tool_calls = deserialize_tool_calls(payload["tools"])
      returns = deserialize_returns(payload["content"])
      original_tool_calls = payload["original_tool_calls"]
      usage = payload["usage"]
      reasoning_content = payload["reasoning_content"]
      compaction = payload["compaction"]
      extra = {tool_calls:, original_tool_calls:, tools: @params[:tools], usage:, reasoning_content:, compaction:}.compact
      content = returns.nil? ? deserialize_content(payload["content"]) : returns
      LLM::Message.new(payload["role"], content, extra)
    end

    private

    def deserialize_content(content)
      case content
      when Array
        content.map { deserialize_content(_1) }
      when Hash
        deserialize_object(content)
      else
        content
      end
    end

    def deserialize_object(object)
      case object["__llm_kind__"]
      when "image_url"
        LLM::Object.from(value: object["value"], kind: :image_url)
      when "local_file"
        LLM::Object.from(value: LLM.File(object["path"]), kind: :local_file)
      when "remote_file"
        LLM::Object.from(value: LLM::Object.from(object["value"] || {}), kind: :remote_file)
      else
        object
      end
    end

    def deserialize_tool_calls(items)
      items ||= []
      items.empty? ? nil : items
    end

    def deserialize_returns(items)
      returns = [*items].filter_map do |item|
        next unless Hash === item
        id, name, value = item.values_at("id", "name", "value")
        next if name.nil? || value.nil?
        LLM::Function::Return.new(id, name, value)
      end
      returns.empty? ? nil : returns
    end
  end

  include Deserializer
end
