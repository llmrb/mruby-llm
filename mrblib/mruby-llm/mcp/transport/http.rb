# frozen_string_literal: true

module LLM::MCP::Transport
  class HTTP

    def initialize(url:, headers: {}, timeout: nil)
      @uri = LLM::URI.parse(url)
      @headers = headers
      @timeout = timeout
      @queue = []
      @monitor = Monitor.new
      @running = false
      @curl = Curl.new
      @curl.timeout = timeout if timeout && @curl.respond_to?(:timeout=)
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
      request = ::HTTP::Request.new
      request.method = "POST"
      request.body = LLM.json.dump(message)
      if request.respond_to?(:headers) && Hash === request.headers
        request.headers["content-type"] = "application/json"
        headers.each { request.headers[_1] = _2 }
      end

      raw = @curl.send(uri.to_s, request)
      response = Net::HTTPResponse.from_http(raw)
      unless response.code.to_i.between?(200, 299)
        raise LLM::MCP::Error, "MCP transport write failed with HTTP #{response.code}"
      end

      content_type = response["content-type"].to_s
      if content_type.include?("text/event-stream")
        parser = LLM::EventStream::Parser.new
        parser.register EventHandler.new { enqueue(_1) }
        parser << response.body.to_s
        parser.free
      else
        payload = response.body.to_s
        enqueue(LLM.json.load(payload)) unless payload.empty?
      end
    ensure
      @response = nil
      @stream_parser = nil
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

    attr_reader :uri, :headers, :timeout
    def enqueue(message)
      lock { @queue << message }
    end

    def lock(&)
      @monitor.synchronize(&)
    end
  end
end
