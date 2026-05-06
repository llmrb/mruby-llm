# frozen_string_literal: true

require_relative "rakelib/mruby-llm/tasks/binary"

task default: :help

desc "Show mruby-llm maintenance entry points"
task :help do
  puts "mruby-llm is an mrbgem."
  puts
  puts "Build through an mruby checkout with:"
  puts "  ruby minirake MRUBY_CONFIG=/absolute/path/to/mruby-llm/build_config/mruby-llm.rb"
  puts
  puts "Convenience build from this repo:"
  puts "  rake build"
  puts '  rake "binary[repl.rb,repl]"'
  puts "  MRUBY_DIR=/path/to/mruby rake build"
end

desc "Build mruby-llm through an mruby checkout and copy binaries into ./bin"
task :build do
  LLM::Task::Binary.build_runtime!
end

desc "Build a native executable from input Ruby to bin/output"
task :binary, [:input, :output] => :build do |_task, args|
  LLM::Task::Binary.build(input: args[:input] || "repl.rb", output: args[:output])
end
