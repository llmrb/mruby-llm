# frozen_string_literal: true

##
# The {LLM::JSON LLM::JSON} module wraps the underlying JSON implementation
# used by mruby-llm.
#
# It preserves the normal `load` API and normalizes values through
# {LLM::Utils.serialize LLM::Utils.serialize} before `dump`, so runtime
# objects such as {LLM::Object LLM::Object} and schema leaves can be encoded
# into plain JSON data.
# @private
module LLM::JSON
  Errors = [::JSON::ParserError].freeze
  extend self


  ##
  # Serialize a value to JSON after normalizing nested runtime objects.
  # @param [Object] value
  # @return [String]
  def dump(value, ...)
    ::JSON.dump(LLM::Utils.serialize(value), ...)
  end

  ##
  # Parse a JSON string.
  # @return [Object]
  def load(...)
    ::JSON.load(...)
  end
end
