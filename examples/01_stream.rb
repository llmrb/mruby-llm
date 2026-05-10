class ReadFile < LLM::Tool
  name "read-file"
  description "reads a file"
  parameter :path, String, "The path to a file"
  required %i[path]

  def call(path:)
    {contents: File.read(path)}
  end
end

class Stream < LLM::Stream
  def on_content(content)
    $stdout << content
  end

  def on_tool_call(tool, error)
    $stdout << "Running #{tool.name}"
  end
end

llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
ctx = LLM::Agent.new(llm, tools: [ReadFile], stream: Stream.new)
loop do
  print "> "
  ctx.talk(gets)
  puts
end
