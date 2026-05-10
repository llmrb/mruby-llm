# frozen_string_literal: true

module LLM::URI
  ##
  # {LLM::URI::Parsed LLM::URI::Parsed} is a small parsed URI object
  # for the mruby port.
  #
  # It only implements the subset of URI state currently needed by the
  # transport layer.
  class Parsed
    PATTERN = /\A([a-z][a-z0-9+\-.]*):\/\/([^\/?#:]+)(?::(\d+))?([^?#]*)?(\?[^#]*)?/

    ##
    # @return [String, nil]
    attr_reader :scheme

    ##
    # @return [String, nil]
    attr_reader :host

    ##
    # @return [Integer, nil]
    attr_reader :port

    ##
    # @return [String]
    attr_reader :request_uri

    ##
    # @param [#to_s] value
    # @return [LLM::URI::Parsed]
    def initialize(value)
      @value = value.to_s
      match = PATTERN.match(@value)
      if match
        @scheme = match[1]
        @host = match[2]
        @port = match[3] ? match[3].to_i : default_port(@scheme)
        path = match[4].to_s
        path = "/" if path.empty?
        @request_uri = "#{path}#{match[5]}"
      else
        @scheme = nil
        @host = nil
        @port = nil
        @request_uri = @value.empty? ? "/" : @value
      end
    end

    ##
    # @return [String]
    def to_s
      @value
    end

    private

    def default_port(scheme)
      case scheme
      when "https" then 443
      when "http" then 80
      end
    end
  end
end
