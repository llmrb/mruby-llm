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
    # Only synchronous execution is exposed in the mruby port for now.
    #
    # @param [Symbol] strategy
    # @return [Array<LLM::Function::Return>]
    def spawn(strategy = :call)
      raise ArgumentError, "Unknown strategy: #{strategy.inspect}. Expected :call" unless strategy == :call
      call
    end

    ##
    # @param [Symbol] strategy
    # @return [Array<LLM::Function::Return>]
    def wait(strategy = :call)
      spawn(strategy)
    end
  end
end
