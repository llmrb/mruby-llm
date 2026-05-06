# frozen_string_literal: true

class LLM::MCP

  include RPC

  @clients = {}

  def self.clients
    @clients
  end

  def self.stdio(llm = nil, **stdio)
    new(llm, stdio: stdio)
  end

  def self.http(llm = nil, **http)
    new(llm, http: http)
  end

  def initialize(llm = nil, stdio: nil, http: nil, timeout: 30)
    @llm = llm
    @timeout = timeout
    if stdio && http
      raise ArgumentError, "stdio and http are mutually exclusive"
    elsif stdio
      @command = Command.new(**stdio)
      @transport = Transport::Stdio.new(command: @command)
    elsif http
      @transport = Transport::HTTP.new(**http, timeout: timeout)
    else
      raise ArgumentError, "stdio or http is required"
    end
  end

  def start
    transport.start
    call(transport, "initialize", {clientInfo: {name: "llm.rb", version: LLM::VERSION}})
    call(transport, "notifications/initialized")
    nil
  end

  def stop
    transport.stop
    nil
  end

  def run
    start
    yield
  ensure
    stop
  end

  def persist!
    transport.persist!
    self
  end
  alias_method :persistent, :persist!

  def tools
    res = call(transport, "tools/list")
    [*res["tools"]].map { LLM::Tool.mcp(self, _1) }
  end

  def prompts
    res = call(transport, "prompts/list")
    LLM::Object.from(res["prompts"])
  end

  def find_prompt(name:, arguments: nil)
    params = {name: name}
    params[:arguments] = arguments if arguments
    res = call(transport, "prompts/get", params)
    res["messages"] = [*res["messages"]].map do |message|
      LLM::Message.new(
        message["role"],
        adapt_content(message["content"]),
        {original_content: message["content"]}
      )
    end
    LLM::Object.from(res)
  end
  alias_method :get_prompt, :find_prompt

  def call_tool(name, arguments = {})
    res = call(transport, "tools/call", {name: name, arguments: arguments})
    adapt_tool_result(res)
  end

  private

  attr_reader :llm, :command, :transport, :timeout

  def adapt_content(content)
    case content
    when String
      content
    when Hash
      content["type"] == "text" ? content["text"].to_s : LLM::Object.from(content)
    when Array
      content.map { adapt_content(_1) }
    else
      content
    end
  end

  def adapt_tool_result(result)
    if result["structuredContent"]
      result["structuredContent"]
    elsif result["content"]
      {content: result["content"]}
    else
      result
    end
  end
end
