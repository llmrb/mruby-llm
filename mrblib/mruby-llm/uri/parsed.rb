# frozen_string_literal: true

module LLM::URI
  ##
  # {LLM::URI::Parsed LLM::URI::Parsed} is a small parsed URI object
  # for the mruby port.
  #
  # It only implements the subset of URI state currently needed by the
  # transport layer.
  class Parsed
    ##
    # Separate regexp are required due to https://github.com/mruby/mruby/issues/6853
    ABSOLUTE_HOST_PORT_PATH_QUERY_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      :
      (?<port>\d+)
      (?<path>/[^\?#]*)
      (?<query>\?[^\#]*)?
      (?:\#.*)?
      \z
    }x
    ABSOLUTE_HOST_PORT_QUERY_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      :
      (?<port>\d+)
      (?<query>\?[^\#]*)
      (?:\#.*)?
      \z
    }x
    ABSOLUTE_HOST_PATH_QUERY_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      (?<path>/[^\?#]*)
      (?<query>\?[^\#]*)?
      (?:\#.*)?
      \z
    }x
    ABSOLUTE_HOST_PATH_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      (?<path>/[^\?#]*)
      \z
    }x
    ABSOLUTE_HOST_QUERY_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      (?<query>\?[^\#]*)
      (?:\#.*)?
      \z
    }x
    ABSOLUTE_HOST_PORT_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      :
      (?<port>\d+)
      \z
    }x
    ABSOLUTE_HOST_PORT_PATH_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      :
      (?<port>\d+)
      (?<path>/[^\?#]*)
      (?:\#.*)?
      \z
    }x
    ABSOLUTE_HOST_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      \z
    }x
    RELATIVE_PATTERN = %r{
      \A
      (?<path>[^\#]*)
      (?:\#.*)?
      \z
    }x

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
      if match = ABSOLUTE_HOST_PORT_PATH_QUERY_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = match[:port].to_i
        @request_uri = "#{match[:path].to_s.empty? ? "/" : match[:path]}#{match[:query]}"
      elsif match = ABSOLUTE_HOST_PORT_QUERY_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = match[:port].to_i
        @request_uri = "/#{match[:query]}"
      elsif match = ABSOLUTE_HOST_PATH_QUERY_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = default_port(@scheme)
        @request_uri = "#{match[:path].to_s.empty? ? "/" : match[:path]}#{match[:query]}"
      elsif match = ABSOLUTE_HOST_PATH_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = default_port(@scheme)
        @request_uri = match[:path]
      elsif match = ABSOLUTE_HOST_QUERY_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = default_port(@scheme)
        @request_uri = "/#{match[:query]}"
      elsif match = ABSOLUTE_HOST_PORT_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = match[:port].to_i
        @request_uri = "/"
      elsif match = ABSOLUTE_HOST_PORT_PATH_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = match[:port].to_i
        @request_uri = match[:path]
      elsif match = ABSOLUTE_HOST_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = default_port(@scheme)
        @request_uri = "/"
      else
        match = RELATIVE_PATTERN.match(@value)
        @scheme = nil
        @host = nil
        @port = nil
        @request_uri = match[:path].to_s.empty? ? "/" : match[:path]
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
