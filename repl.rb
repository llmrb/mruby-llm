# frozen_string_literal: true

key = ENV["DEEPSEEK_SECRET"] || ENV["DEEPSEEK_KEY"]
if key.to_s.empty?
  STDERR.puts "DEEPSEEK_SECRET or DEEPSEEK_KEY is required"
  exit 1
end

class Stream < LLM::Stream
  def on_content(content)
    $stdout.write(content)
    $stdout.flush
  end
end

llm = LLM.deepseek(key: key)
ctx = LLM::Context.new(llm, stream: Stream.new)

loop do
  print "> "
  input = STDIN.gets
  break unless input
  input = input.strip
  next if input.empty?
  ctx.talk(input)
  puts
end
