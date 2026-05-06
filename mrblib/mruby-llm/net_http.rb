# frozen_string_literal: true

module URI
  def self.encode_www_form(params)
    [*params].map do |key, value|
      "#{escape(key)}=#{escape(value)}"
    end.join("&")
  end

  def self.parse(value)
    value.to_s
  end

  def self.escape(value)
    value.to_s.bytes.map do |byte|
      char = byte.chr
      if /[A-Za-z0-9_.~-]/.match?(char)
        char
      else
        "%%%02X" % byte
      end
    end.join
  end
end

module Net
  class HTTP
    class HTTPRequest
      attr_accessor :body, :body_stream
      attr_reader :path, :headers

      def initialize(path, headers = nil)
        @path = path.to_s
        @headers = {}
        (headers || {}).each { self[_1] = _2 }
      end

      def method
        self.class::METHOD
      end

      def [](key)
        @headers[normalize_header(key)]
      end

      def []=(key, value)
        @headers[normalize_header(key)] = value.to_s
      end

      def each_header(&block)
        @headers.each(&block)
      end

      private

      def normalize_header(key)
        key.to_s.downcase
      end
    end

    class Get < HTTPRequest
      METHOD = "GET"
    end

    class Post < HTTPRequest
      METHOD = "POST"
    end

    class Put < HTTPRequest
      METHOD = "PUT"
    end

    class Patch < HTTPRequest
      METHOD = "PATCH"
    end

    class Delete < HTTPRequest
      METHOD = "DELETE"
    end
  end

  class HTTPResponse
    attr_accessor :body
    attr_reader :code, :headers

    def self.from_http(response)
      code =
        if response.respond_to?(:status_code)
          response.status_code.to_i
        elsif response.respond_to?(:status)
          response.status.to_i
        else
          0
        end
      klass = classify(code)
      klass.new(code, response.respond_to?(:headers) ? response.headers : {}, response.respond_to?(:body) ? response.body : "")
    end

    def self.classify(code)
      case code
      when 200 then HTTPOK
      when 400 then HTTPBadRequest
      when 401 then HTTPUnauthorized
      when 429 then HTTPTooManyRequests
      when 200..299 then HTTPSuccess
      when 500..599 then HTTPServerError
      else HTTPResponse
      end
    end

    def initialize(code, headers = {}, body = "")
      @code = code.to_i
      @headers = {}
      (headers || {}).each { @headers[normalize_header(_1)] = _2 }
      @body = body
    end

    def [](key)
      @headers[normalize_header(key)]
    end

    def []=(key, value)
      @headers[normalize_header(key)] = value
    end

    def read_body(receiver = nil)
      return @body unless block_given? || receiver
      if receiver
        receiver << @body.to_s
      else
        yield @body.to_s
      end
      @body
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} @code=#{@code} @headers=#{@headers.inspect} @body=#{@body.inspect}>"
    end

    private

    def normalize_header(key)
      key.to_s.downcase
    end
  end

  class HTTPSuccess < HTTPResponse
  end

  class HTTPOK < HTTPSuccess
  end

  class HTTPBadRequest < HTTPResponse
  end

  class HTTPUnauthorized < HTTPResponse
  end

  class HTTPTooManyRequests < HTTPResponse
  end

  class HTTPServerError < HTTPResponse
  end
end
