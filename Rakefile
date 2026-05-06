# frozen_string_literal: true

require "fileutils"

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
  puts "  MRUBY_DIR=/path/to/mruby rake build"
end

desc "Build mruby-llm through an mruby checkout and copy binaries into ./bin"
task :build do
  root = File.expand_path(__dir__)
  mruby_dir = File.expand_path(ENV["MRUBY_DIR"] || File.join(root, "..", "mruby"))
  config = File.join(root, "build_config", "mruby-llm.rb")
  target = "mruby-llm"
  build_dir = File.join(mruby_dir, "build", target)
  source_bin = File.join(build_dir, "bin")
  target_bin = File.join(root, "bin")
  unless File.exist?(File.join(mruby_dir, "minirake"))
    abort "mruby checkout not found: #{mruby_dir}"
  end
  Dir.chdir(mruby_dir) do
    sh "ruby minirake clean"
    sh "ruby minirake MRUBY_CONFIG=#{config}"
  end
  FileUtils.rm_rf(target_bin)
  FileUtils.mkdir_p(target_bin)
  FileUtils.cp_r(Dir[File.join(source_bin, "*")], target_bin)
  puts "Built binaries copied to #{target_bin}"
end
