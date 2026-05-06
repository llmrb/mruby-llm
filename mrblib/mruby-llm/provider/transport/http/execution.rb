# frozen_string_literal: true

module LLM::Provider::Transport
  class HTTP
    ##
    # Internal HTTP request execution methods for {LLM::Provider}.
    #
    # This module handles provider-side HTTP execution, response parsing,
    # streaming, and request body setup through
    # {LLM::Provider::Transport::HTTP}.
    #
    # @api private
    module HTTP::Execution
      private

      ##
      # Executes a HTTP request
      # @param [Net::HTTPRequest] request
      #  The request to send
      # @param [Proc] b
      #  A block to yield the response to (optional)
      # @return [Net::HTTPResponse]
      #  The response from the server
      # @raise [LLM::Error::Unauthorized]
      #  When authentication fails
      # @raise [LLM::Error::RateLimit]
      #  When the rate limit is exceeded
      # @raise [LLM::Error]
      #  When any other unsuccessful status code is returned
      # @raise [SystemCallError]
      #  When there is a network error at the operating system level
      # @return [Net::HTTPResponse]
      def execute(request:, operation:, stream: nil, stream_parser: self.stream_parser, model: nil, inputs: nil, &b)
        owner = transport.request_owner
        tracer = self.tracer
        span = tracer.on_request_start(operation:, model:, inputs:)
        res = transport.perform(request, owner:, stream:, stream_parser:)
        b.call(res) if b && Net::HTTPSuccess === res
        [handle_response(res, tracer, span), span, tracer]
      rescue *transport.interrupt_errors
        raise LLM::Interrupt, "request interrupted" if transport.interrupted?(owner)
        raise
      end

      ##
      # Handles the response from a request
      # @param [Net::HTTPResponse] res
      #  The response to handle
      # @param [Object, nil] span
      #  The span
      # @return [Net::HTTPResponse]
      def handle_response(res, tracer, span)
        case res
        when Net::HTTPOK then res.body = parse_response(res)
        else error_handler.new(tracer, span, res).raise_error!
        end
        res
      end

      ##
      # Parse a HTTP response
      # @param [Net::HTTPResponse] res
      # @return [LLM::Object, String]
      def parse_response(res)
        case res["content-type"]
        when %r{\Aapplication/json\s*} then LLM::Object.from(LLM.json.load(res.body))
        else res.body
        end
      end

      ##
      # @param [Net::HTTPRequest] req
      #  The request to set the body stream for
      # @param [IO] io
      #  The IO object to set as the body stream
      # @return [void]
      def set_body_stream(req, io)
        req.body_stream = io
        req["transfer-encoding"] = "chunked" unless req["content-length"]
      end

    end
  end
end

LLM::Provider.include(LLM::Provider::Transport::HTTP::Execution)
