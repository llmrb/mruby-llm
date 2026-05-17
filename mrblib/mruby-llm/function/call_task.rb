# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::CallTask} class wraps a single direct function call
  # behind the same task-like interface used by spawned concurrency modes.
  class CallTask
    ##
    # @return [LLM::Function]
    attr_reader :function

    ##
    # @param [LLM::Function] function
    # @return [LLM::Function::CallTask]
    def initialize(function)
      @function = function
    end

    ##
    # @return [Boolean]
    def alive?
      false
    end

    ##
    # @return [nil]
    def interrupt!
      function.interrupt!
      nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # @return [LLM::Function::Return]
    def wait
      function.call
    end
    alias_method :value, :wait

    ##
    # @return [Class]
    def group_class
      LLM::Function::TaskGroup
    end
  end
end
