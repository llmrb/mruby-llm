# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::Task} class wraps a single mruby-task-backed
  # function call.
  class Task
    ##
    # @return [Object]
    attr_reader :task

    ##
    # @return [LLM::Function, nil]
    attr_reader :function

    ##
    # @param [Task] task
    # @param [LLM::Function, nil] function
    # @return [LLM::Function::Task]
    def initialize(task, function = nil)
      @task = task
      @function = function
    end

    ##
    # @return [Boolean]
    def alive?
      return task.alive? if task.respond_to?(:alive?)
      return task.status != :DORMANT if ::Task === task
      false
    end

    ##
    # @return [nil]
    def interrupt!
      if task.respond_to?(:interrupt!)
        task.interrupt!
      elsif ::Task === task
        task.terminate
      end
      function&.interrupt!
      nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # @return [LLM::Function::Return]
    def wait
      if ::Task === task
        task.join
        normalize(task.value)
      else
        task.wait
      end
    end
    alias_method :value, :wait

    private

    def normalize(value)
      return value unless Exception === value
      return value if LLM::Function::Return === value
      function ? function.error(value) : value
    end
  end
end
