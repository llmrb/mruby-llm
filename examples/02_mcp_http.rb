llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
mcp = LLM::MCP.http(
  url: "https://api.githubcopilot.com/mcp/",
  headers: {"Authorization" => "Bearer #{ENV["GITHUB_PAT"]}"}
)

mcp.run do
  agent = LLM::Agent.new(llm, stream: $stdout, tools: mcp.tools)
  agent.talk "Tell me about my GitHub account"
end
