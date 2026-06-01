# frozen_string_literal: true

module LLM
  ##
  # The {LLM::Tracer::Logger LLM::Tracer::Logger} class writes tracing events
  # to an IO-like object.
  #
  # Each event is emitted as one JSON object per line. This keeps the mruby
  # implementation small while still making request and tool execution visible.
  #
  # @example
  #   llm = LLM.openai(key: ENV["KEY"])
  #   llm.tracer = LLM::Tracer::Logger.new(llm, io: $stdout)
  class Tracer::Logger < Tracer
    ##
    # @param (see LLM::Tracer#initialize)
    # @option options [#write, #<<] :io
    #  The IO-like object that receives JSON lines.
    def initialize(provider, options = {})
      super
      @io = options[:io] || $stdout
    end

    ##
    # @param (see LLM::Tracer#on_request_start)
    # @return [Hash]
    def on_request_start(operation:, model: nil, **)
      emit(event: "request.start", operation:, model:)
    end

    ##
    # @param (see LLM::Tracer#on_request_finish)
    # @return [Hash]
    def on_request_finish(operation:, res:, model: nil, **)
      emit(event: "request.finish", operation:, model:, response_id: res.id, usage: res.usage.to_h)
    end

    ##
    # @param (see LLM::Tracer#on_request_error)
    # @return [Hash]
    def on_request_error(ex:, **)
      emit(event: "request.error", error_class: ex.class.to_s, error_message: ex.message)
    end

    ##
    # @param (see LLM::Tracer#on_tool_start)
    # @return [Hash]
    def on_tool_start(id:, name:, arguments:, model:, **)
      emit(event: "tool.start", operation: "execute_tool", tool_id: id, tool_name: name, tool_arguments: arguments, model:)
    end

    ##
    # @param (see LLM::Tracer#on_tool_finish)
    # @return [Hash]
    def on_tool_finish(result:, **)
      emit(event: "tool.finish", operation: "execute_tool", tool_id: result.id, tool_name: result.name, tool_result: result.value)
    end

    ##
    # @param (see LLM::Tracer#on_tool_error)
    # @return [Hash]
    def on_tool_error(ex:, **)
      emit(event: "tool.error", operation: "execute_tool", error_class: ex.class.to_s, error_message: ex.message)
    end

    private

    def emit(payload)
      event = {tracer: "mruby-llm", provider: provider_name}.merge(payload).compact
      write(LLM.json.dump(event))
      write("\n")
      @io.flush if @io.respond_to?(:flush)
      event
    end

    def write(string)
      @io.respond_to?(:write) ? @io.write(string) : @io << string
    end

  end
end
