# frozen_string_literal: true

module LLM
  @monitors = {require: ::Monitor.new, clients: ::Monitor.new,
               inherited: ::Monitor.new, registry: ::Monitor.new, mcp: ::Monitor.new}
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
