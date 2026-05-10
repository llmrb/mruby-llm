# frozen_string_literal: true

class LLM::Provider
  ##
  # The {LLM::Provider::Transport LLM::Provider::Transport} class defines the
  # transport interface used by {LLM::Provider}. Custom transports can subclass
  # it and override the methods they need.
  #
  # A transport is responsible for executing provider requests and returning a
  # {Net::HTTPResponse}-like object. Streaming transports should feed response
  # chunks into the given `stream_parser`.
  #
  # Required methods:
  # - {#perform}
  #
  # Optional methods with defaults:
  # - {#request_owner}
  # - {#interrupt_errors}
  # - {#interrupt!}
  # - {#interrupted?}
  # - {#persist!}
  # - {#persistent?}
  class Transport
    ##
    # Executes a provider request.
    # @param [Net::HTTPRequest] request
    # @param [Object] owner
    #  The execution owner associated with this request.
    # @param [Object, nil] stream
    #  Optional stream callback object.
    # @param [Class, nil] stream_parser
    #  Optional provider stream parser class.
    # @raise [NotImplementedError]
    # @return [Net::HTTPResponse]
    def perform(request, owner:, stream: nil, stream_parser: nil)
      raise NotImplementedError, "#{self.class} must implement #perform"
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
    # Enables persistence mode when supported.
    # @return [LLM::Provider::Transport]
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
end
