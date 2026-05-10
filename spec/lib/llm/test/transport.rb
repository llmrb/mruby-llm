# frozen_string_literal: true

module LLM::Test
  class Transport < LLM::Transport
    Route = Struct.new(:fixture, :code, :headers, keyword_init: true)

    attr_reader :requests

    def initialize(root:)
      @root = root
      @routes = {}
      @requests = []
      @interrupts = {}
    end

    def stub(method, path, fixture:, code: 200, headers: {"content-type" => "application/json"})
      key = [method.to_s.upcase, path.to_s]
      (@routes[key] ||= []) << Route.new(
        fixture:,
        code:,
        headers:
      )
      self
    end

    def request(request, owner:, stream: nil, &)
      @requests << capture_request(request)
      routes = @routes.fetch([request.method, request.path]) do
        raise "no fixture stub for #{request.method} #{request.path}"
      end
      route = routes.shift
      raise "no remaining fixture stubs for #{request.method} #{request.path}" unless route
      body = File.read(File.join(@root, route.fixture))
      if stream
        perform_streaming(route, body, stream)
      else
        response = Net::HTTPResponse.classify(route.code).new(route.code, route.headers, body)
        block_given? && Net::HTTPSuccess === response ? yield(response) : response
      end
    end

    def request_owner
      self
    end

    def interrupt_errors
      []
    end

    def interrupt!(owner)
      @interrupts[owner] = true
      nil
    end

    def interrupted?(owner)
      @interrupts.delete(owner)
    end

    def persist!
      self
    end
    alias_method :persistent, :persist!

    def persistent?
      false
    end

    private

    def perform_streaming(route, body, stream)
      response = Net::HTTPResponse.classify(route.code).new(route.code, route.headers, "")
      decoder = stream.decoder.new(stream.parser.new(stream.streamer))
      decoder << body
      parsed = decoder.body
      response.body = (Hash === parsed || Array === parsed) ? LLM::Object.from(parsed) : parsed
      response
    ensure
      decoder&.free
    end

    def capture_request(request)
      {
        method: request.method,
        path: request.path,
        headers: request.headers.dup,
        body: request.body || read_body_stream(request.body_stream)
      }
    end

    def read_body_stream(io)
      return nil unless io
      body = +""
      while (chunk = io.read(16 * 1024))
        body << chunk
      end
      body
    end
  end
end
