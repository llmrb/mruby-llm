MRuby::Build.new("mruby-llm") do |conf|
  conf.toolchain
  conf.gembox "default"
  conf.enable_debug
  # FreeBSD and similar systems install libcurl under /usr/local.
  conf.cc.include_paths << "/usr/local/include"
  conf.linker.library_paths << "/usr/local/lib"
  conf.gem File.expand_path("..", __dir__)
  conf.enable_bintest
  conf.enable_test
end
