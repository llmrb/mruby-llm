# frozen_string_literal: true

class LLM::MCP
  module RPC
    def call(transport, method, params = {})
      message = {jsonrpc: "2.0", method: method, params: default_params(method).merge(params)}
      if notification?(method)
        router.write(transport, message)
        return nil
      end
      id, mailbox = router.register
      begin
        router.write(transport, message.merge(id: id))
        recv(transport, id, mailbox)
      ensure
        router.clear(id)
      end
    end

    private

    def recv(transport, id, mailbox)
      poll(timeout: timeout, ex: [IOError, EOFError]) do
        loop do
          res = mailbox.pop
          return handle_response(id, res) if res
          route_response(router.read(transport), id)
        end
      end
    end

    def default_params(method)
      case method
      when "initialize"
        {protocolVersion: "2025-03-26", capabilities: {}}
      else
        {}
      end
    end

    def notification?(method)
      method.to_s.start_with?("notifications/")
    end

    def timeout
      @timeout ||= 5
    end

    def poll(timeout:, ex: [])
      start = ::Time.now.to_f
      loop do
        return yield
      rescue => err
        raise err unless ex.any? { _1 === err }
        duration = ::Time.now.to_f - start
        raise LLM::MCP::TimeoutError, "MCP process timed out" if duration > timeout
        sleep 0.05
      end
    end

    def handle_response(id, res)
      raise LLM::MCP::Error.from(response: res) if res["error"]
      return res["result"] if res["id"] == id
      raise LLM::MCP::MismatchError.new(expected_id: id, actual_id: res["id"])
    end

    def route_response(res, id)
      return nil if res["method"]
      return router.route(res) if res.key?("id")
      raise LLM::MCP::MismatchError.new(expected_id: id, actual_id: nil)
    end

    def router
      @router ||= LLM::MCP::Router.new
    end
  end
end
