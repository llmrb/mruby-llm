# frozen_string_literal: true

##
# @private
module LLM::Utils
  extend self

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
end
