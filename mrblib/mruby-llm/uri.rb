# frozen_string_literal: true

module LLM
  ##
  # A small URI compatibility shim for the mruby port.
  #
  # The original {https://github.com/llmrb/llm.rb llm.rb} runtime used parts of
  # Ruby's stdlib {https://ruby-doc.org/stdlib-3.3.0/libdoc/uri/rdoc/URI.html URI}
  # API in provider and transport code. mruby does not ship that same surface,
  # so this module provides the small subset the port needs in order to keep the
  # existing llm.rb request-building code largely unchanged.
  #
  # This is not a complete URI implementation. It currently exists to support:
  #
  # - query-string generation through {.encode_www_form}
  # - simple parsing through {.parse}
  # - percent-escaping through {.escape}
  module URI
    ##
    # Build a query string from key-value pairs.
    # @param [Hash, Array<Array(#to_s, #to_s)>] params
    #  The params to encode
    # @return [String]
    def self.encode_www_form(params)
      [*params].map do |key, value|
        "#{escape(key)}=#{escape(value)}"
      end.join("&")
    end

    ##
    # Parse a URI-like value for the mruby transport layer.
    #
    # @param [#to_s] value
    #  The URI-like value
    # @return [LLM::URI::Parsed]
    def self.parse(value)
      Parsed.new(value)
    end

    ##
    # Percent-escape a value for query-string usage.
    # @param [#to_s] value
    #  The value to escape
    # @return [String]
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
end
