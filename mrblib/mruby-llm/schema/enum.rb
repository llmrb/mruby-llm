# frozen_string_literal: true

class LLM::Schema
  ##
  # The {LLM::Schema::Enum LLM::Schema::Enum} class represents a
  # string value constrained to one of a fixed set of values.
  class Enum
    ##
    # Returns a string leaf constrained to the given values
    # @param [Array<String>] values
    # @return [LLM::Schema::String]
    def self.[](*values)
      LLM::Schema::String.new.enum(*values)
    end
  end
end
