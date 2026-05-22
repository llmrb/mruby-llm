# frozen_string_literal: true

##
# @private
module LLM::Utils
  extend self

  ##
  # Normalizes an HTTP API base path.
  #
  # Blank paths normalize to an empty string. Non-empty paths are
  # prefixed with a leading slash and stripped of trailing slashes.
  #
  # @param [String, nil] path
  # @return [String]
  def normalize_base_path(path)
    path = path.to_s.strip
    return "" if path.empty? || path == "/"
    path = "/#{path}" unless path.start_with?("/")
    rstrip(path, "/")
  end

  ##
  # Resolves a configured option against an object instance.
  #
  # Proc values are evaluated with `instance_exec`, symbol values are
  # optionally sent to the object as method calls, hashes are duplicated,
  # and all other values are returned as-is.
  #
  # @param [Object] obj
  # @param [Object] option
  # @param [Boolean] resolve_symbol
  # @return [Object]
  def resolve_option(obj, option, resolve_symbol: true)
    case option
    when Proc then obj.instance_exec(&option)
    when Symbol then resolve_symbol ? obj.send(option) : option
    when Hash then option.dup
    else option
    end
  end

  ##
  # Resolves a transport from an optional override or returns a default.
  #
  # @param [URI] uri
  # @param [LLM::Transport, Class, nil] transport
  # @param [Integer, nil] timeout
  # @return [LLM::Transport]
  def resolve_transport(uri, transport, timeout)
    return default_transport(uri, timeout) if transport.nil?
    if Class === transport && transport <= LLM::Transport
      transport.new(
        host: uri.host,
        port: uri.port,
        timeout:,
        ssl: uri.scheme == "https"
      )
    else
      transport
    end
  end

  ##
  # Returns the default curl-based transport for a given URI.
  #
  # @param [URI] uri
  # @param [Integer, nil] timeout
  # @return [LLM::Transport::Curl]
  def default_transport(uri, timeout)
    LLM::Transport::Curl.new(
      host: uri.host,
      port: uri.port,
      timeout:,
      ssl: uri.scheme == "https"
    )
  end

  ##
  # Deep-serialize a runtime value into plain JSON-serializable data.
  #
  # Arrays and Hashes are traversed recursively. Objects that respond to
  # `to_h` are recursively normalized through that Hash representation until
  # only plain values remain.
  #
  # @param [Array, Hash, LLM::Object, #to_h, Object] value
  #  The value to normalize
  # @return [Array, Hash, String, Numeric, Boolean, nil, Object]
  def serialize(value)
    if Array === value
      value.map { serialize(_1) }
    elsif Hash === value
      value.each_with_object({}) { |(k, v), acc| acc[k] = serialize(v) }
    elsif value.nil? || String === value || Numeric === value || value == true || value == false
      value
    elsif value.respond_to?(:to_h)
      serialize(value.to_h)
    else
      value
    end
  end

  ##
  # Split a string by a literal delimiter.
  # @param [String] value
  #  The string to split
  # @param [String] delimiter
  #  The literal delimiter
  # @return [Array<String>]
  def split(value, delimiter)
    return [value] if delimiter.empty?
    parts = []
    chunk = +""
    index = 0
    limit = value.size - delimiter.size
    while index <= limit
      if value[index, delimiter.size] == delimiter
        parts << chunk
        chunk = +""
        index += delimiter.size
      else
        chunk << value[index]
        index += 1
      end
    end
    while index < value.size
      chunk << value[index]
      index += 1
    end
    parts << chunk
    parts
  end

  ##
  # Remove trailing occurrences of a literal suffix.
  # @param [String] value
  #  The input string
  # @param [String] suffix
  #  The literal suffix to trim
  # @return [String]
  def rstrip(value, suffix)
    return value if suffix.empty?
    while value.length > suffix.length && value.end_with?(suffix)
      value = value[0, value.length - suffix.length]
    end
    value
  end
end
