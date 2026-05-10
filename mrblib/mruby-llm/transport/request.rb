# frozen_string_literal: true

class LLM::Transport
  ##
  # {LLM::Transport::Request LLM::Transport::Request} defines the
  # normalized request interface expected by transports.
  #
  # Providers build request objects through this class, then hand them
  # to a transport for execution without depending on any specific HTTP
  # client library.
  class Request
    ##
    # @return [Object]
    attr_accessor :body

    ##
    # @return [IO, nil]
    attr_accessor :body_stream

    ##
    # @return [String]
    attr_reader :method

    ##
    # @return [String]
    attr_reader :path

    ##
    # @return [Hash]
    attr_reader :headers

    ##
    # @param [String] path
    # @param [Hash, nil] headers
    # @return [LLM::Transport::Request]
    def self.get(path, headers = nil)
      new("GET", path, headers)
    end

    ##
    # @param [String] path
    # @param [Hash, nil] headers
    # @return [LLM::Transport::Request]
    def self.post(path, headers = nil)
      new("POST", path, headers)
    end

    ##
    # @param [String] path
    # @param [Hash, nil] headers
    # @return [LLM::Transport::Request]
    def self.put(path, headers = nil)
      new("PUT", path, headers)
    end

    ##
    # @param [String] path
    # @param [Hash, nil] headers
    # @return [LLM::Transport::Request]
    def self.patch(path, headers = nil)
      new("PATCH", path, headers)
    end

    ##
    # @param [String] path
    # @param [Hash, nil] headers
    # @return [LLM::Transport::Request]
    def self.delete(path, headers = nil)
      new("DELETE", path, headers)
    end

    ##
    # @param [String] method
    # @param [String] path
    # @param [Hash, nil] headers
    # @return [LLM::Transport::Request]
    def initialize(method, path, headers = nil)
      @method = method.to_s.upcase
      @path = path.to_s
      @headers = {}
      (headers || {}).each { self[_1] = _2 }
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
    # @return [String]
    def []=(key, value)
      @headers[normalize_header(key)] = value.to_s
    end

    ##
    # @yieldparam [String] key
    # @yieldparam [String] value
    # @return [Hash]
    def each_header(&block)
      @headers.each(&block)
    end

    private

    def normalize_header(key)
      key.to_s.downcase
    end
  end
end
