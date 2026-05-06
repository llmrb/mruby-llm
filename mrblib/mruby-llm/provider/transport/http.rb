# frozen_string_literal: true

class LLM::Provider
  module Transport
    ##
    # The {LLM::Provider::Transport::HTTP LLM::Provider::Transport::HTTP}
    # class manages HTTP connections for {LLM::Provider}. The mruby port
    # currently exposes only transient request behavior while the HTTP
    # transport is being rewritten away from net/http.
    #
    # @api private
    class HTTP
      require_relative "http/stream_decoder"
      require_relative "http/interruptible"

      ##
      # @param [String] host
      # @param [Integer] port
      # @param [Integer] timeout
      # @param [Boolean] ssl
      # @param [Boolean] persistent
      # @return [LLM::Provider::Transport::HTTP]
      def initialize(host:, port:, timeout:, ssl:, persistent: false)
        @host = host
        @port = port
        @timeout = timeout
        @ssl = ssl
        @curl = Curl.new
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
      # Persistent transport is not currently supported in the mruby port.
      # @return [LLM::Provider::Transport::HTTP]
      def persist!
        self
      end
      alias_method :persistent, :persist!

      ##
      # @return [Boolean]
      def persistent?
        false
      end

      ##
      # Performs a request through Curl and returns a Net::HTTPResponse-like
      # wrapper so the existing provider layer can stay unchanged.
      def perform(request, owner:, stream: nil, stream_parser: nil)
        set_request(ActiveRequest.new(curl: @curl), owner)
        if stream
          perform_streaming(request, owner, stream, stream_parser)
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
        Net::HTTPResponse.from_http(@curl.send(request_url(request), build_http_request(request)))
      end

      def perform_streaming(request, owner, stream, stream_parser)
        response = nil
        decoder = StreamDecoder.new(stream_parser.new(stream))
        raw = @curl.send(request_url(request), build_http_request(request)) do |header, chunk|
          raise LLM::Interrupt, "request interrupted" if interrupted?(owner)
          response ||= Net::HTTPResponse.from_http(header)
          decoder << chunk
        end
        response ||= Net::HTTPResponse.from_http(raw)
        body = decoder.body
        if response.code.to_i == 0 && !response.headers.empty?
          response = Net::HTTPOK.new(200, response.headers, response.body)
        end
        response.body = (Hash === body || Array === body) ? LLM::Object.from(body) : body
        response
      ensure
        decoder&.free
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
        "#{ssl ? "https" : "http"}://#{host}:#{port}#{path}"
      end

      def lock(&)
        @monitor.synchronize(&)
      end
    end
  end
end
