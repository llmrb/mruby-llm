# frozen_string_literal: true

class LLM::Transport
  ##
  # The {LLM::Transport LLM::Transport} class defines the execution
  # interface used by {LLM::Provider}.
  #
  # Custom transports can subclass this class and override {#request} to
  # execute provider requests without changing request adapters or
  # response adapters.
  #
  # Only {#request} is required. The remaining methods are optional hooks
  # for interruption, owner tracking, and request body setup.
  class << self
    def curl
      Curl
    end
  end

  ##
  # Performs a request through the transport.
  # @param [Net::HTTPRequest] request
  # @param [Object] owner
  # @param [LLM::Object, nil] stream
  # @yieldparam [Net::HTTPResponse] response
  # @return [Object]
  def request(request, owner:, stream: nil, &)
    raise NotImplementedError, "#{self.class} must implement #request"
  end

  ##
  # Returns the current request owner token.
  # @return [Object]
  def request_owner
    self
  end

  ##
  # Returns transport-specific interruption errors.
  # @return [Array<Class>]
  def interrupt_errors
    []
  end

  ##
  # Interrupts an active request, if supported.
  # @param [Object] owner
  # @return [nil]
  def interrupt!(owner)
    nil
  end

  ##
  # Returns whether an execution owner was interrupted.
  # @param [Object] owner
  # @return [Boolean, nil]
  def interrupted?(owner)
    nil
  end

  ##
  # @param [Net::HTTPRequest] request
  # @param [IO] io
  # @return [void]
  def set_body_stream(request, io)
    request.body_stream = io
    request["transfer-encoding"] = "chunked" unless request["content-length"]
  end

  ##
  # Enables persistence mode when supported.
  # @return [LLM::Transport]
  def persist!
    self
  end
  alias_method :persistent, :persist!

  ##
  # Returns whether the transport is persistent.
  # @return [Boolean]
  def persistent?
    false
  end
end
