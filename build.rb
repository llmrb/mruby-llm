MRuby::Build.new("mruby-llm") do |conf|
  curldir = File.expand_path(ENV["CURLDIR"] || "/usr/local")
  conf.toolchain

  conf.cc.include_paths << File.join(curldir, "include")
  conf.linker.library_paths << File.join(curldir, "lib")

  conf.gembox "default"
  conf.gem "."
  conf.gem github: "0x1eef/mruby-minitest", branch: "main"
  conf.enable_debug
end
