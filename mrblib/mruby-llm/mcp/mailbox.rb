# frozen_string_literal: true

class LLM::MCP
  class Mailbox
    def initialize
      @messages = []
      @monitor = Monitor.new
    end

    def <<(message)
      @monitor.synchronize { @messages << message }
      self
    end

    def pop
      @monitor.synchronize { @messages.shift }
    end
  end
end
