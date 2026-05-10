require "rbconfig"

desc "build binaries"
task build: [:preflight] do
  Dir.chdir ENV["MRUBY"] do
    argv = ["-S", "rake", "MRUBY_CONFIG=#{__dir__}/build.rb", "clean", "build"]
    sh RbConfig.ruby, *argv
    rm_rf File.join(__dir__, "bin")
    mv File.join(Dir.pwd, "build", "mruby-llm", "bin"), __dir__
  end
end

desc "build test binaries"
task "build:test": [:preflight] do
  Dir.chdir ENV["MRUBY"] do
    argv = ["-S", "rake", "MRUBY_CONFIG=#{__dir__}/build.rb", "clean", "build"]
    sh({"ENV" => "TEST"}, RbConfig.ruby, *argv)
    rm_rf File.join(__dir__, "bin")
    mv File.join(Dir.pwd, "build", "mruby-llm", "bin"), __dir__
  end
end

desc "run tests"
task test: ["build:test"] do
  Dir["spec/*_spec.rb"].each do |t|
    sh "bin/mruby #{t}"
  end
end

task :preflight do
  if ENV["MRUBY"].nil? || !File.directory?(ENV["MRUBY"])
    warn "error: $MRUBY does not reference an mruby checkout"
    exit 1
  end
end
