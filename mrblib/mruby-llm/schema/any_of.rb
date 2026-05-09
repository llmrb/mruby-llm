# frozen_string_literal: true

class LLM::Schema
  ##
  # The {LLM::Schema::AnyOf LLM::Schema::AnyOf} class represents an
  # anyOf union in a JSON schema. It is a subclass of
  # {LLM::Schema::Leaf LLM::Schema::Leaf}.
  class AnyOf < Leaf
    ##
    # Returns an anyOf union for the given types.
    # @return [LLM::Schema::AnyOf]
    def self.[](*types)
      schema = LLM::Schema.new
      new(types.map { LLM::Schema::Utils.resolve(schema, _1) })
    end

    ##
    # @param [Array<LLM::Schema::Leaf>] values
    #  The values allowed by the union
    # @return [LLM::Schema::AnyOf]
    def initialize(values)
      @values = values
    end

    ##
    # @return [Hash]
    def to_h
      super.merge!(anyOf: @values)
    end
  end
end
