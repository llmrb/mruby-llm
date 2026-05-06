# frozen_string_literal: true

module LLM::MCP::Transport
  class Stdio
    def initialize(command:)
      @command = command
    end

    def start
      raise LLM::MCP::Error, "MCP transport is already running" if command.alive?
      command.start
    end

    def stop
      command.stop
    end

    def write(message)
      raise LLM::MCP::Error, "MCP transport is not running" unless command.alive?
      command.write(LLM.json.dump(message))
    end

    def read_nonblock
      raise LLM::MCP::Error, "MCP transport is not running" unless command.alive?
      LLM.json.load(command.read_nonblock)
    end

    def wait
      command.wait
    end

    def persist!
      self
    end
    alias_method :persistent, :persist!

    private

    attr_reader :command
  end
end
