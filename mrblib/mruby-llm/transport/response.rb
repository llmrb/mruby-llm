# frozen_string_literal: true

class LLM::Transport
  ##
  # {LLM::Transport::Response LLM::Transport::Response} defines the
  # normalized HTTP response interface expected by transports and
  # provider error handlers.
  #
  # Custom transports can execute requests through any underlying HTTP
  # client, then adapt that client's native response object to this
  # interface.
  #
  # This keeps the transport boundary focused on one contract:
  # providers, execution, and error handlers only need a response
  # object that implements
  # {LLM::Transport::Response LLM::Transport::Response}, regardless of
  # how the request was actually performed.
  class Response
    ##
    # @return [Object]
    attr_accessor :body

    ##
    # @return [String]
    attr_reader :code

    ##
    # @return [Hash]
    attr_reader :headers

    ##
    # @param [Object] res
    # @return [LLM::Transport::Response]
    def self.from(res)
      return res if LLM::Transport::Response === res
      code =
        if res.respond_to?(:status_code)
          res.status_code.to_i
        elsif res.respond_to?(:status)
          res.status.to_i
        elsif res.respond_to?(:code)
          res.code.to_i
        else
          0
        end
      new(code, res.respond_to?(:headers) ? res.headers : {}, res.respond_to?(:body) ? res.body : "")
    end

    ##
    # @param [String, #to_i] code
    # @param [Hash] headers
    # @param [Object] body
    # @return [LLM::Transport::Response]
    def initialize(code, headers = {}, body = "")
      @code = code.to_i
      @headers = {}
      (headers || {}).each { @headers[normalize_header(_1)] = _2 }
      @body = body
    end

    ##
    # @param [String] key
    # @return [String, nil]
    def [](key)
      @headers[normalize_header(key)]
    end

    ##
    # @param [String] key
    # @param [Object] value
    # @return [Object]
    def []=(key, value)
      @headers[normalize_header(key)] = value
    end

    ##
    # @param [Object, nil] receiver
    # @yieldparam [String] chunk
    # @return [Object]
    def read_body(receiver = nil)
      return @body unless block_given? || receiver
      if receiver
        receiver << @body.to_s
      else
        yield @body.to_s
      end
      @body
    end

    ##
    # @return [Boolean]
    def success?
      code.between?(200, 299)
    end
    alias_method :ok?, :success?

    ##
    # @return [Boolean]
    def bad_request?
      code == 400
    end

    ##
    # @return [Boolean]
    def unauthorized?
      code == 401
    end

    ##
    # @return [Boolean]
    def forbidden?
      code == 403
    end

    ##
    # @return [Boolean]
    def not_found?
      code == 404
    end

    ##
    # @return [Boolean]
    def rate_limited?
      code == 429
    end

    ##
    # @return [Boolean]
    def server_error?
      code.between?(500, 599)
    end

    ##
    # @return [String]
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} @code=#{@code} @headers=#{@headers.inspect} @body=#{@body.inspect}>"
    end

    private

    def normalize_header(key)
      key.to_s.downcase
    end
  end
end
