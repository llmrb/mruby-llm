# frozen_string_literal: true

class LLM::MCP
  class Router
    def initialize
      @request_id = -1
      @pending = {}
      @lock = Monitor.new
      @writer = Monitor.new
      @reader = Monitor.new
    end

    def register
      @lock.synchronize do
        @request_id += 1
        mailbox = LLM::MCP::Mailbox.new
        @pending[@request_id] = mailbox
        [@request_id, mailbox]
      end
    end

    def clear(id)
      @lock.synchronize { @pending.delete(id) }
    end

    def read(transport)
      @reader.synchronize { transport.read_nonblock }
    end

    def write(transport, message)
      @writer.synchronize { transport.write(message) }
    end

    def route(response)
      mailbox = @lock.synchronize { @pending[response["id"]] }
      raise LLM::MCP::MismatchError.new(expected_id: nil, actual_id: response["id"]) unless mailbox
      mailbox << response
      nil
    end
  end
end
