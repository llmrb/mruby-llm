MRuby::Build.new("mruby-llm") do |conf|
  curldir = File.expand_path(ENV["CURLDIR"] || "/usr/local")
  conf.toolchain
  conf.gembox "default"
  conf.enable_debug
  conf.cc.include_paths << File.join(curldir, "include")
  conf.linker.library_paths << File.join(curldir, "lib")
  conf.gem File.expand_path("..", __dir__)
  conf.enable_bintest
  conf.enable_test
end
