# frozen_string_literal: true

class LLM::Transport
  ##
  # Internal request execution methods for {LLM::Provider}.
  #
  # @api private
  module Execution
    private

    ##
    # Executes a HTTP request
    # @param [LLM::Transport::Request] request
    # @param [Proc] b
    # @return [LLM::Transport::Response]
    def execute(request:, operation:, stream: nil, stream_parser: self.stream_parser, model: nil, inputs: nil, &b)
      stream &&= LLM::Object.from(streamer: stream, parser: stream_parser, decoder: stream_decoder)
      owner = transport.request_owner
      tracer = self.tracer
      span = tracer.on_request_start(operation:, model:, inputs:)
      res = transport.request(request, owner:, stream:, &b)
      [handle_response(res, tracer, span), span, tracer]
    rescue *transport.interrupt_errors
      raise LLM::Interrupt, "request interrupted" if transport.interrupted?(owner)
      raise
    end

    ##
    # Handles the response from a request
    # @param [LLM::Transport::Response] res
    # @param [Object, nil] span
    # @return [LLM::Transport::Response]
    def handle_response(res, tracer, span)
      res.success? ? res.body = parse_response(res) : error_handler.new(tracer, span, res).raise_error!
      res
    end

    ##
    # Parse a HTTP response
    # @param [LLM::Transport::Response] res
    # @return [LLM::Object, String]
    def parse_response(res)
      case res["content-type"]
      when %r{\Aapplication/json\s*} then LLM::Object.from(LLM.json.load(res.body))
      else res.body
      end
    end

    ##
    # @return [Class]
    def stream_decoder
      LLM::Transport::Curl::StreamDecoder
    end
  end
end

LLM::Provider.include(LLM::Transport::Execution)
