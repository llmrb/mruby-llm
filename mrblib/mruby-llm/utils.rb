# frozen_string_literal: true

##
# @private
module LLM::Utils
  extend self

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
