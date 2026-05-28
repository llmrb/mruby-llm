# frozen_string_literal: true

class LLM::Transport
  ##
  # The {LLM::Transport::Curl LLM::Transport::Curl} class manages HTTP
  # requests for {LLM::Provider} through mruby-curl.
  #
  # @api private
  class Curl < self

    ##
    # @param [String] host
    # @param [Integer] port
    # @param [Integer] timeout
    # @param [Boolean] ssl
    # @param [Boolean] persistent
    # @return [LLM::Transport::Curl]
    def initialize(host:, port:, timeout:, ssl:, persistent: false)
      @host = host
      @port = port
      @timeout = timeout
      @ssl = ssl
      @curl = ::Curl.multi
      @curl.timeout = timeout if @curl.respond_to?(:timeout=)
      @monitor = Monitor.new
    end

    ##
    # Interrupt an active request, if any.
    # @param [Fiber] owner
    # @return [nil]
    def interrupt!(owner)
      super
    end

    ##
    # Returns whether an execution owner was interrupted.
    # @param [Fiber] owner
    # @return [Boolean, nil]
    def interrupted?(owner)
      super
    end

    ##
    # Returns the current request owner.
    # @return [Object]
    def request_owner
      self
    end

    ##
    # Performs a request through Curl and returns a transport response
    # wrapper so the provider layer can stay transport-agnostic.
    def request(request, owner:, stream: nil, &b)
      set_request(ActiveRequest.new(curl: @curl), owner)
      if stream
        perform_streaming(request, owner, stream)
      elsif b
        res = perform_request(request)
        res.success? ? b.call(res) : res
      else
        perform_request(request)
      end
    ensure
      clear_request(owner)
    end

    ##
    # @return [String]
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} @persistent=false>"
    end

    private

    attr_reader :host, :port, :timeout, :ssl

    def perform_request(request)
      curl_request = @curl.send(request_url(request), build_http_request(request))
      perform_until_done(curl_request)
      LLM::Transport::Response.from(curl_request.response)
    end

    def perform_streaming(request, owner, stream)
      res = nil
      raw_body = +""
      decoder_class = stream.decoder == LLM::Transport::StreamDecoder ? LLM::Transport::Curl::StreamDecoder : stream.decoder
      decoder = decoder_class.new(stream.parser.new(stream.streamer))
      curl_request = @curl.send(request_url(request), build_http_request(request)) do |header, chunk|
        raise LLM::Interrupt, "request interrupted" if interrupted?(owner)
        res ||= LLM::Transport::Response.from(header)
        if res.success? && res["content-type"].to_s.include?("text/event-stream")
          decoder.chunked = res["transfer-encoding"].to_s.downcase.include?("chunked") if decoder.respond_to?(:chunked=)
          decoder << chunk
        else
          raw_body << chunk.to_s
        end
      end
      perform_until_done(curl_request, owner)
      res ||= LLM::Transport::Response.from(curl_request.response)
      if raw_body.empty?
        body = decoder.body
        res.body = (Hash === body || Array === body) ? LLM::Object.from(body) : body
      else
        res.body = raw_body
      end
      res
    ensure
      decoder&.free
    end

    def perform_until_done(request, owner = nil)
      until request.done?
        raise LLM::Interrupt, "request interrupted" if owner && interrupted?(owner)
        @curl.perform
        Task.pass
      end
      request.response
    end

    def build_http_request(request)
      http_request = ::HTTP::Request.new
      http_request.method = request.method
      headers = {}
      request.headers.each { headers[_1] = _2 } if request.respond_to?(:headers)
      if http_request.respond_to?(:headers)
        existing = http_request.headers
        if Hash === existing
          headers.each { existing[_1] = _2 }
        end
      end
      body = request.body || read_body_stream(request.body_stream)
      http_request.body = body if body
      http_request
    end

    def read_body_stream(io)
      return nil unless io
      body = +""
      while (chunk = io.read(16 * 1024))
        body << chunk
      end
      body
    end

    def request_url(request)
      path = request.path
      return path if path.start_with?("http://", "https://")
      scheme = ssl ? "https" : "http"
      default_port = ssl ? 443 : 80
      authority = port && port.to_i > 0 && port.to_i != default_port ? "#{host}:#{port}" : host
      "#{scheme}://#{authority}#{path}"
    end

    def lock(&)
      @monitor.synchronize(&)
    end
  end
end
