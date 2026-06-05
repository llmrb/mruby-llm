# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::Array} module extends the array
  # returned by {LLM::Context#functions} with methods
  # that can call all pending functions sequentially or
  # concurrently. The return values can be reported back
  # to the LLM on the next turn.
  module Array
    ##
    # Calls all functions in a collection sequentially.
    # @return [Array<LLM::Function::Return>]
    #  Returns values to be reported back to the LLM.
    def call
      map(&:call)
    end

    ##
    # Calls all functions in a collection through the mruby runtime surface.
    #
    # @param [Symbol] strategy
    # @return [LLM::Function::CallGroup, LLM::Function::TaskGroup]
    def spawn(strategy = :call)
      case strategy
      when :call
        CallGroup.new(self)
      when :task
        TaskGroup.new(map { |fn| LLM::Function::Task.new(::Task.new { fn.call }, fn) })
      else
        raise ArgumentError, "Unknown strategy: #{strategy.inspect}. Expected :call or :task"
      end
    end

    ##
    # @param [Symbol] strategy
    # @return [Array<LLM::Function::Return>]
    def wait(strategy = :call)
      spawn(strategy)
    end

    ##
    # @return [LLM::Function::Array]
    def -(other)
      super(other).extend(Array)
    end
  end
end
