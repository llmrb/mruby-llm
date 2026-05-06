# frozen_string_literal: true

class LLM::MCP
  Error = Class.new(LLM::Error) do
    attr_reader :code, :data

    def self.from(response:)
      error = response.fetch("error")
      new(*error.values_at("message", "code", "data"))
    end

    def initialize(message, code = nil, data = nil)
      super(message)
      @code = code
      @data = data
    end
  end

  MismatchError = Class.new(Error) do
    attr_reader :expected_id, :actual_id

    def initialize(expected_id:, actual_id:)
      @expected_id = expected_id
      @actual_id = actual_id
      super(message)
    end

    def message
      "mismatched MCP response id #{actual_id.inspect} while waiting for #{expected_id.inspect}"
    end
  end

  TimeoutError = Class.new(Error)
end
