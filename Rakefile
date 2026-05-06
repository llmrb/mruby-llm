# frozen_string_literal: true

require_relative "build/build"

task default: :help

desc "Show mruby-llm maintenance entry points"
task :help do
  puts "mruby-llm is an mrbgem."
  puts
  puts "Build through an mruby checkout with:"
  puts "  ruby minirake MRUBY_CONFIG=/absolute/path/to/mruby-llm/build_config/mruby-llm.rb"
  puts
  puts "Convenience build from this repo:"
  puts "  rake build:toolchain"
  puts '  rake "build:dynamic:binary[repl.rb,repl]"'
  puts '  rake "build:static:binary[repl.rb,repl]"'
  puts "  CURLDIR=/path/to/curl-prefix rake build:curl"
  puts "  MRUBY_DIR=/path/to/mruby rake build:toolchain"
end

namespace :build do
  desc "Build mruby-llm through an mruby checkout and copy binaries into ./bin"
  task :toolchain do
    Build::Binaries.build_toolchain!
  end
end

namespace :build do
  namespace :dynamic do
    desc "Build a dynamically linked native executable from input Ruby to bin/output"
    task :binary, [:input, :output] => "build:toolchain" do |_task, args|
      Build::Binaries.build_dynamic(input: args[:input] || "repl.rb", output: args[:output])
    end
  end

  namespace :static do
    desc "Build a statically linked native executable from input Ruby to bin/output"
    task :binary, [:input, :output] => "build:toolchain" do |_task, args|
      Build::Binaries.build_static(input: args[:input] || "repl.rb", output: args[:output])
    end
  end
end
