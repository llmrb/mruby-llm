# frozen_string_literal: true

module LLM
  require_relative "mruby-llm/monitor"
  require_relative "mruby-llm/uri"
  require_relative "mruby-llm/tracer"
  require_relative "mruby-llm/error"
  require_relative "mruby-llm/hash"
  require_relative "mruby-llm/contract"
  require_relative "mruby-llm/registry"
  require_relative "mruby-llm/cost"
  require_relative "mruby-llm/usage"
  require_relative "mruby-llm/prompt"
  require_relative "mruby-llm/schema"
  require_relative "mruby-llm/object"
  require_relative "mruby-llm/model"
  require_relative "mruby-llm/version"
  require_relative "mruby-llm/utils"
  require_relative "mruby-llm/message"
  require_relative "mruby-llm/response"
  require_relative "mruby-llm/mime"
  require_relative "mruby-llm/multipart"
  require_relative "mruby-llm/file"
  require_relative "mruby-llm/pipe"
  require_relative "mruby-llm/mcp"
  require_relative "mruby-llm/stream"
  require_relative "mruby-llm/provider"
  require_relative "mruby-llm/context"
  require_relative "mruby-llm/agent"
  require_relative "mruby-llm/compactor"
  require_relative "mruby-llm/buffer"
  require_relative "mruby-llm/function"
  require_relative "mruby-llm/eventstream"
  require_relative "mruby-llm/eventhandler"
  require_relative "mruby-llm/tool"
  require_relative "mruby-llm/skill"
  require_relative "mruby-llm/loop_guard"

  @monitors = {require: Monitor.new, clients: Monitor.new,
               inherited: Monitor.new, registry: Monitor.new, mcp: Monitor.new}
  @registry = {}
  @clients = {}

  def self.clients
    @clients
  end

  def self.registry_for(llm)
    lock(:registry) do
      name = Symbol === llm ? llm : llm.name
      @registry[name] ||= Registry.for(name)
    end
  end

  def self.json
    ::JSON
  end

  def self.function(key, &b)
    LLM::Function.new(key, &b)
  end

  def self.anthropic(**)
    LLM::Anthropic.new(**)
  end

  def self.google(**)
    LLM::Google.new(**)
  end

  def self.ollama(key: nil, **)
    LLM::Ollama.new(key:, **)
  end

  def self.llamacpp(key: nil, **)
    LLM::LlamaCpp.new(key:, **)
  end

  def self.deepseek(**)
    LLM::DeepSeek.new(**)
  end

  def self.openai(**)
    LLM::OpenAI.new(**)
  end

  def self.xai(**)
    LLM::XAI.new(**)
  end

  def self.zai(**)
    LLM::ZAI.new(**)
  end

  def self.mcp(llm = nil, **)
    LLM::MCP.new(llm, **)
  end

  def self.lock(name, &)
    @monitors[name].synchronize(&)
  end
end
