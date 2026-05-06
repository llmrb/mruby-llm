# frozen_string_literal: true

class LLM::Schema
  ##
  # The {LLM::Schema::AllOf LLM::Schema::AllOf} class represents an
  # allOf union in a JSON schema. It is a subclass of
  # {LLM::Schema::Leaf LLM::Schema::Leaf}.
  class AllOf < Leaf
    ##
    # Returns an allOf union for the given types.
    # @return [LLM::Schema::AllOf]
    def self.[](*types)
      schema = LLM::Schema.new
      new(types.map { LLM::Schema::Utils.resolve(schema, _1) })
    end

    ##
    # @param [Array<LLM::Schema::Leaf>] values
    #  The values required by the union
    # @return [LLM::Schema::AllOf]
    def initialize(values)
      @values = values
    end

    ##
    # @return [Hash]
    def to_h
      super.merge!(allOf: serialize(@values))
    end
  end
end
