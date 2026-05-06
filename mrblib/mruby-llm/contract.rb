# frozen_string_literal: true

module LLM
  ##
  # The `LLM::Contract` module provides the ability for modules
  # who are extended by it to implement contracts which must be
  # implemented by other modules who include a given contract.
  #
  # @example
  #   module LLM::Contract
  #      # ..
  #   end
  #
  #   module LLM::Contract
  #     module Completion
  #       extend LLM::Contract
  #       # inheriting modules must implement these methods
  #       # otherwise an error is raised on include
  #       def foo = nil
  #       def bar = nil
  #     end
  #   end
  #
  #   module LLM::OpenAI::ResponseAdapter
  #     module Completion
  #       def foo = nil
  #       def bar = nil
  #       include LLM::Contract::Completion
  #     end
  #   end
  module Contract
    ContractError = Class.new(LLM::Error)
    require_relative "contract/completion"

    ##
    # @api private
    def included(mod)
      meths = mod.instance_methods(false)
      if meths.empty?
        raise ContractError, "#{mod} does not implement any methods required by #{self}"
      end
      missing = instance_methods - meths
      if missing.any?
        raise ContractError, "#{mod} does not implement methods (#{missing.join(", ")}) required by #{self}"
      end
    end
  end
end
