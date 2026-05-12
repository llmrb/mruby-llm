MRuby::Build.new("mruby-llm") do |conf|
  profile = ENV.fetch("BUILD_PROFILE", "test")
  curldir = File.expand_path(ENV["CURLDIR"] || "/usr/local")

  conf.toolchain

  conf.cc.include_paths << File.join(curldir, "include")
  conf.linker.library_paths << File.join(curldir, "lib")

  conf.gembox "default"

  case profile
  when "test", "developer"
    conf.enable_debug
    ENV["ENV"] = "TEST"
  when "production"
    conf.cc.flags << "-DNDEBUG"
  else
    raise ArgumentError, "unknown BUILD_PROFILE=#{profile.inspect}"
  end

  conf.gem File.expand_path(__dir__)
end
