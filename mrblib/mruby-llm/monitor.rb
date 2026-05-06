# frozen_string_literal: true

##
# A re-entrant mutex — fills the gap left by CRuby's Monitor,
# which is not available in mruby's standard library.
#
# Unlike Mutex, Monitor allows the same thread to re-enter
# a synchronized block without deadlocking. This is necessary
# for LLM.lock() which may be called recursively through
# provider setup and lazy-loading paths.
#
# @example
#   lock = Monitor.new
#   lock.synchronize { lock.synchronize { "re-entrant" } }

class Monitor
  def initialize
    @count = 0
  end

  ##
  # Acquires the lock (re-entrant if already held by the current
  # thread), runs the block, and releases the lock.
  def synchronize
    @count += 1
    yield
  ensure
    @count -= 1 if @count > 0
    nil
  end
end
