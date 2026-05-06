# frozen_string_literal: true

class LLM::Stream
  ##
  # A small queue for collecting streamed tool results.
  class Queue
    ##
    # @param [LLM::Stream] stream
    # @return [LLM::Stream::Queue]
    def initialize(stream)
      @stream = stream
      @items = []
    end

    ##
    # Enqueue a function return.
    # @param [LLM::Function::Return] item
    # @return [LLM::Stream::Queue]
    def <<(item)
      @items << item
      self
    end

    ##
    # Returns true when the queue is empty.
    # @return [Boolean]
    def empty?
      @items.empty?
    end

    ##
    # @return [nil]
    def interrupt!
      @items.each(&:interrupt!)
      nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # Waits for queued results and returns them.
    # @param [Symbol] strategy
    # @return [Array<LLM::Function::Return>]
    def wait(strategy = :call)
      raise ArgumentError, "Unknown strategy: #{strategy.inspect}. Expected :call" unless strategy == :call
      returns = @items.shift(@items.length)
      returns.each do |result|
        unless LLM::Function::Return === result
          raise ArgumentError, "Synchronous mruby stream queue only accepts LLM::Function::Return values"
        end
      end
      fire_hooks(returns)
    end
    alias_method :value, :wait

    private

    def fire_hooks(results)
      results.each do |result|
        @stream.on_tool_return(nil, result)
      end
      results
    end
  end
end
