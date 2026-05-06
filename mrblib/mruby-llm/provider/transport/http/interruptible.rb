# frozen_string_literal: true

class LLM::Provider
  ##
  # Internal request interruption methods for
  # {LLM::Provider::Transport::HTTP}.
  #
  # This module tracks active requests by execution owner and provides
  # the logic used to interrupt an in-flight request by closing the
  # active HTTP connection.
  #
  # @api private
  module Transport::HTTP::Interruptible
    INTERRUPT_ERRORS = [::IOError, ::EOFError].freeze
    ActiveRequest = Struct.new(:curl, keyword_init: true)

    def interrupt_errors
      [*INTERRUPT_ERRORS, *optional_interrupt_errors]
    end

    ##
    # Interrupt an active request, if any.
    # @param [Fiber] owner
    #  The execution owner whose request should be interrupted
    # @return [nil]
    def interrupt!(owner)
      lock { (@interrupts ||= {})[owner] = true }
      owner.stop if owner.respond_to?(:stop)
    rescue *interrupt_errors
      nil
    end

    private

    ##
    # Returns the active request for an execution owner.
    # @param [Fiber] owner
    # @return [ActiveRequest, nil]
    def request_for(owner)
      lock do
        @requests ||= {}
        @requests[owner]
      end
    end

    ##
    # Records an active request for an execution owner.
    # @param [ActiveRequest] req
    # @param [Fiber] owner
    # @return [ActiveRequest]
    def set_request(req, owner)
      lock do
        @requests ||= {}
        @requests[owner] = req
      end
    end

    ##
    # Clears the active request for an execution owner.
    # @param [Fiber] owner
    # @return [Request, nil]
    def clear_request(owner)
      lock { @requests&.delete(owner) }
    end

    ##
    # Returns whether an execution owner was interrupted.
    # @param [Fiber] owner
    # @return [Boolean, nil]
    def interrupted?(owner)
      lock { @interrupts&.delete(owner) }
    end

    def optional_interrupt_errors = []
  end
end

LLM::Provider::Transport::HTTP.include(LLM::Provider::Transport::HTTP::Interruptible)
