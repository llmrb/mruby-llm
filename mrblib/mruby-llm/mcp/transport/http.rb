# frozen_string_literal: true

module LLM::MCP::Transport
  class HTTP

    def initialize(url:, headers: {}, timeout: nil, transport: nil)
      @uri = LLM::URI.parse(url)
      @headers = headers
      @transport = resolve_transport(transport, timeout: timeout)
      @queue = []
      @monitor = Monitor.new
      @running = false
    end

    def start
      lock do
        raise LLM::MCP::Error, "MCP transport is already running" if running?
        @queue.clear
        @running = true
      end
    end

    def stop
      lock do
        return nil unless running?
        @running = false
        nil
      end
    end

    def write(message)
      raise LLM::MCP::Error, "MCP transport is not running" unless running?
      req = LLM::Transport::Request.post(uri.request_uri, headers.merge("content-type" => "application/json"))
      req.body = LLM.json.dump(message)
      res = transport.request(req, owner: self)
      read(res) if res.success?
      raise LLM::MCP::Error, "MCP transport write failed with HTTP #{res.code}" unless res.success?
    end

    def read_nonblock
      lock do
        raise LLM::MCP::Error, "MCP transport is not running" unless running?
        raise IOError, "no complete message available" if @queue.empty?
        @queue.shift
      end
    end

    def running?
      @running
    end

    def persist!
      self
    end
    alias_method :persistent, :persist!

    private

    attr_reader :uri, :headers, :transport

    def resolve_transport(transport, timeout:)
      return default_transport(timeout: timeout) if transport.nil?
      if Class === transport && transport <= LLM::Transport
        return transport.new(host: uri.host, port: uri.port, timeout: timeout, ssl: uri.scheme == "https")
      end
      transport
    end

    def default_transport(timeout:)
      LLM::Transport::Curl.new(host: uri.host, port: uri.port, timeout: timeout, ssl: uri.scheme == "https")
    end

    def read(res)
      if res["content-type"].to_s.include?("text/event-stream")
        parser = LLM::EventStream::Parser.new
        parser.register EventHandler.new { enqueue(_1) }
        res.read_body { parser << _1 }
        parser.free
      else
        payload = +""
        res.read_body { payload << _1 }
        enqueue(LLM.json.load(payload)) unless payload.empty?
      end
    end

    def enqueue(message)
      lock { @queue << message }
    end

    def lock(&)
      @monitor.synchronize(&)
    end
  end
end
