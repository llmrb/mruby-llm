# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::ForkTask} class wraps a fork-backed function call.
  class ForkTask
    ##
    # @return [Integer]
    attr_reader :pid

    ##
    # @return [LLM::Function]
    attr_reader :function

    ##
    # @param [LLM::Function] fn
    # @return [LLM::Function::ForkTask]
    def initialize(fn)
      @fn = fn
      @function = fn
      @ch = chan(:json, lock: :file)
      @ch.nonblock!
      @value = nil
      @waited = false
      @pid = fork { call }
    end

    ##
    # @return [Boolean]
    def alive?
      return false if @waited
      result = Process.waitpid(@pid, Process::WNOHANG)
      @waited = !result.nil?
      !@waited
    rescue Errno::ECHILD
      @waited = true
      false
    end

    ##
    # @return [nil]
    def interrupt!
      return if @waited
      Process.kill("KILL", -@pid)
      nil
    rescue Errno::ESRCH, Errno::EINVAL
      Process.kill("KILL", @pid) rescue nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # @return [LLM::Function::Return]
    def wait
      return @value if @value
      loop do
        hash = @ch.read
        @value = deserialize(hash)
        reap
        return @value
      rescue Chan::WaitReadable
        unless alive?
          @value = @fn.error(LLM::Error.new("tool call did not produce a result"))
          return @value
        end
        pass
      end
    ensure
      @ch.close
    end
    alias_method :value, :wait

    ##
    # @return [Class]
    def group_class
      LLM::Function::TaskGroup
    end

    private

    def call
      Process.setpgid(0, 0)
      write(@fn.call.to_h)
    rescue => ex
      write(@fn.error(ex).to_h)
    ensure
      @ch.close rescue nil
      exit! 0
    end

    def deserialize(hash)
      LLM::Function::Return.new(hash["id"] || hash[:id],
                                hash["name"] || hash[:name],
                                hash["value"] || hash[:value])
    end

    def reap
      return if @waited
      Process.waitpid(@pid)
      @waited = true
    rescue Errno::ECHILD
      @waited = true
    end

    def pass
      task? ? ::Task.pass : sleep(0.01)
    rescue Errno::EINTR
      nil
    end

    def write(value)
      loop do
        @ch.write(value)
        break
      rescue Chan::WaitWritable
        pass
      end
    end

    def task?
      Object.const_defined?(:Task) and ::Task.current
    end
  end
end
