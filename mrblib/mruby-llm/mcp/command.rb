# frozen_string_literal: true

class LLM::MCP
  class Command
    attr_reader :pid

    def initialize(argv:, env: {}, cwd: nil)
      @argv = argv
      @env = env
      @cwd = cwd
      @pid = nil
      @io = nil
      @buffer = +""
    end

    def start
      raise LLM::MCP::Error, "MCP command is already running" if alive?
      @buffer.clear
      @io = ::IO.popen(commandline, "r+")
      @pid = @io.pid
      nil
    end

    def stop
      return nil unless alive?
      @io.close unless @io.closed?
      ::Process.kill("TERM", pid)
      @buffer.clear
      wait
    rescue Errno::ESRCH
      @buffer.clear
      @pid = nil
      @io = nil
      nil
    end

    def alive?
      !@pid.nil? && @io && !@io.closed?
    end

    def write(message)
      @io.write(message)
      @io.write("\n")
      @io.flush
    end

    def read_nonblock(_io = :stdout)
      raise LLM::MCP::Error, "MCP command is not running" unless alive?
      ready = ::IO.select([@io], nil, nil, 0)
      raise IOError, "no complete message available" unless ready

      loop do
        if (index = @buffer.index("\n"))
          return @buffer.slice!(0, index + 1)
        end
        @buffer << @io.sysread(4096)
      end
    rescue EOFError
      raise IOError, "no complete message available"
    end

    def wait
      ::Process.waitpid2(pid)
      @pid = nil
      @io = nil
    rescue Errno::ECHILD
      nil
    end

    private

    attr_reader :argv, :env, :cwd

    def commandline
      parts = []
      parts << "cd #{shellescape(cwd)} &&" if cwd
      env.each do |key, value|
        parts << "#{key}=#{shellescape(value.to_s)}"
      end
      parts << "exec"
      parts.concat(argv.map { shellescape(_1) })
      parts.join(" ")
    end

    def shellescape(value)
      "'" + value.to_s.gsub("'", %q('"'"')) + "'"
    end
  end
end
