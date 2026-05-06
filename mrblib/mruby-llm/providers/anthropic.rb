# frozen_string_literal: true

module LLM
  ##
  # The Anthropic class implements a provider for
  # [Anthropic](https://www.anthropic.com).
  #
  # @example
  #   #!/usr/bin/env ruby
  #   require "llm"
  #
  #   llm = LLM.anthropic(key: ENV["KEY"])
  #   ctx = LLM::Context.new(llm)
  #   ctx.talk ["Tell me about this photo", ctx.local_file("/images/photo.png")]
  #   ctx.messages.select(&:assistant?).each { print "[#{_1.role}]", _1.content, "\n" }
  class Anthropic < Provider
    require_relative "anthropic/utils"
    require_relative "anthropic/error_handler"
    require_relative "anthropic/request_adapter"
    require_relative "anthropic/response_adapter"
    require_relative "anthropic/stream_parser"
    require_relative "anthropic/models"
    require_relative "anthropic/files"
    HOST = "api.anthropic.com"

    ##
    # @param key (see LLM::Provider#initialize)
    def initialize(**)
      super(host: HOST, **)
    end

    ##
    # @return [Symbol]
    #  Returns the provider's name
    def name
      :anthropic
    end

    ##
    # Provides an interface to the chat completions API
    # @see https://docs.anthropic.com/en/api/messages Anthropic docs
    # @param prompt (see LLM::Provider#complete)
    # @param params (see LLM::Provider#complete)
    # @example (see LLM::Provider#complete)
    # @raise (see LLM::Provider#request)
    # @raise [LLM::PromptError]
    #  When given an object a provider does not understand
    # @return (see LLM::Provider#complete)
    def complete(prompt, params = {})
      params, stream, tools, role = normalize_complete_params(params)
      req = build_complete_request(prompt, params, role)
      res, span, tracer = execute(request: req, stream: stream, operation: "chat", model: params[:model])
      res = ResponseAdapter.adapt(res, type: :completion)
        .extend(Module.new { define_method(:__tools__) { tools } })
      tracer.on_request_finish(operation: "chat", model: params[:model], res:, span:)
      res
    end

    ##
    # Provides an interface to Anthropic's models API
    # @see https://docs.anthropic.com/en/api/models-list
    # @return [LLM::Anthropic::Models]
    def models
      LLM::Anthropic::Models.new(self)
    end

    ##
    # Provides an interface to Anthropic's files API
    # @see https://docs.anthropic.com/en/docs/build-with-claude/files Anthropic docs
    # @return [LLM::Anthropic::Files]
    def files
      LLM::Anthropic::Files.new(self)
    end

    ##
    # @return (see LLM::Provider#assistant_role)
    def assistant_role
      "assistant"
    end

    ##
    # Anthropic expects tool results to be sent as user messages
    # containing `tool_result` content blocks rather than a distinct
    # `tool` role.
    # @return (see LLM::Provider#tool_role)
    def tool_role
      :user
    end

    ##
    # Returns the default model for chat completions
    # @see https://docs.anthropic.com/en/docs/about-claude/models/all-models#model-comparison-table claude-sonnet-4-20250514
    # @return [String]
    def default_model
      "claude-sonnet-4-20250514"
    end

    private

    def headers
      lock do
        (@headers || {}).merge(
          "Content-Type" => "application/json",
          "x-api-key" => @key,
          "anthropic-version" => "2023-06-01",
          "anthropic-beta" => "files-api-2025-04-14"
        )
      end
    end

    def stream_parser
      LLM::Anthropic::StreamParser
    end

    def error_handler
      LLM::Anthropic::ErrorHandler
    end

    def normalize_complete_params(params)
      params = {role: :user, model: default_model, max_tokens: 1024}.merge!(params)
      tools = resolve_tools(params.delete(:tools))
      params = [params, adapt_tools(tools)].inject({}, &:merge!).compact
      role, stream = params.delete(:role), params.delete(:stream)
      params[:stream] = true if streamable?(stream) || stream == true
      [params, stream, tools, role]
    end

    def build_complete_request(prompt, params, role)
      messages = build_complete_messages(prompt, params, role)
      payload = adapt(messages)
      body = LLM.json.dump(payload.merge!(params))
      req = Net::HTTP::Post.new("/v1/messages", headers)
      set_body_stream(req, StringIO.new(body))
      req
    end

    def build_complete_messages(prompt, params, role)
      if LLM::Prompt === prompt
        [*(params.delete(:messages) || []), *prompt.to_a]
      else
        [*(params.delete(:messages) || []), Message.new(role, prompt)]
      end
    end
  end
end
