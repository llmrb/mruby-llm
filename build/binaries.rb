# frozen_string_literal: true

require "fileutils"
require "rake/file_utils"

module Build::Binaries
  extend self
  extend FileUtils
  extend RakeFileUtils

  def root
    File.expand_path("..", __dir__)
  end

  def mruby_dir
    File.expand_path(ENV["MRUBY_DIR"] || File.join(root, "..", "mruby"))
  end

  def config
    File.join(root, "build_config", "mruby-llm.rb")
  end

  def curldir
    File.expand_path(ENV["CURLDIR"] || "/usr/local")
  end

  def target_name
    "mruby-llm"
  end

  def build_root
    File.join(mruby_dir, "build", target_name)
  end

  def bin_dir
    File.join(root, "bin")
  end

  def ensure_mruby_checkout!
    return if File.exist?(File.join(mruby_dir, "minirake"))
    raise "mruby checkout not found: #{mruby_dir}"
  end

  def build_toolchain!
    ensure_mruby_checkout!
    source_bin = File.join(build_root, "bin")
    Dir.chdir(mruby_dir) do
      sh "CURLDIR=#{curldir} ruby minirake clean"
      sh "CURLDIR=#{curldir} ruby minirake MRUBY_CONFIG=#{config}"
    end
    rm_rf(bin_dir)
    mkdir_p(bin_dir)
    cp_r(Dir[File.join(source_bin, "*")], bin_dir)
    puts "Built binaries copied to #{bin_dir}"
  end

  def build_dynamic(input:, output: nil)
    out = output || File.basename(input, ".rb")
    script = File.expand_path(input, root)
    work = File.join(root, "tmp", "native", out)
    symbol = out.gsub(/[^A-Za-z0-9_]/, "_")
    mrbc = File.join(build_root, "bin", "mrbc")
    mruby_config = File.join(build_root, "bin", "mruby-config")
    target = File.join(bin_dir, out)
    irep_c = File.join(work, "#{out}_irep.c")
    main_c = File.join(work, "#{out}.c")
    raise "built mrbc not found: #{mrbc}" unless File.exist?(mrbc)
    raise "mruby-config not found: #{mruby_config}" unless File.exist?(mruby_config)
    raise "app script not found: #{script}" unless File.exist?(script)
    mkdir_p(work)
    sh "#{mrbc} -B#{symbol} -o #{irep_c} #{script}"
    File.write(main_c, render_c_template(symbol))
    cflags = `#{mruby_config} --cflags`.strip
    ldflags_before = `#{mruby_config} --ldflags-before-libs`.strip
    libmruby = `#{mruby_config} --libmruby-path`.strip
    libs = `#{mruby_config} --libs`.strip
    ldflags = `#{mruby_config} --ldflags`.strip
    sh "cc #{cflags} #{main_c} #{irep_c} #{ldflags_before} #{libmruby} #{libs} #{ldflags} -o #{target}"
    chmod(0o755, target)
    puts "Built dynamic binary at #{target}"
  end

  def build_static(input:, output: nil)
    out = output || File.basename(input, ".rb")
    script = File.expand_path(input, root)
    work = File.join(root, "tmp", "native", out)
    symbol = out.gsub(/[^A-Za-z0-9_]/, "_")
    mrbc = File.join(build_root, "bin", "mrbc")
    mruby_config = File.join(build_root, "bin", "mruby-config")
    target = File.join(bin_dir, out)
    irep_c = File.join(work, "#{out}_irep.c")
    main_c = File.join(work, "#{out}.c")
    raise "built mrbc not found: #{mrbc}" unless File.exist?(mrbc)
    raise "mruby-config not found: #{mruby_config}" unless File.exist?(mruby_config)
    raise "app script not found: #{script}" unless File.exist?(script)
    mkdir_p(work)
    sh "#{mrbc} -B#{symbol} -o #{irep_c} #{script}"
    File.write(main_c, render_c_template(symbol))
    cflags = `#{mruby_config} --cflags`.strip
    ldflags_before = `#{mruby_config} --ldflags-before-libs`.strip
    libmruby = `#{mruby_config} --libmruby-path`.strip
    libs = static_libs(`#{mruby_config} --libs`.strip)
    ldflags = sanitize_static_ldflags(`#{mruby_config} --ldflags`.strip)
    assert_static_libs_available!(["#{ldflags_before} #{libmruby} #{libs} #{ldflags}"])
    sh "cc -static #{cflags} #{main_c} #{irep_c} #{ldflags_before} #{libmruby} #{libs} #{ldflags} -o #{target}"
    chmod(0o755, target)
    puts "Built static binary at #{target}"
  end

  def static_libs(libs)
    curl = `PKG_CONFIG_PATH=#{curl_pkg_config_path} pkg-config --libs --static libcurl 2>/dev/null`.strip
    return libs if curl.empty?
    libs.sub(/(^|\s)-lcurl(\s|$)/, " #{curl} ")
  end

  def curl_pkg_config_path
    File.join(curldir, "lib", "pkgconfig")
  end

  def sanitize_static_ldflags(flags)
    flags.split.reject { _1.start_with?("-R") }.join(" ")
  end

  def assert_static_libs_available!(parts)
    tokens = parts.join(" ").split
    search_dirs = tokens.grep(/\A-L/).map { _1.delete_prefix("-L") }
    search_dirs.concat(%w[/usr/local/lib /usr/lib /lib]).uniq!
    missing = tokens.grep(/\A-l/).map { _1.delete_prefix("-l") }.uniq.filter_map do |name|
      next if library_archive_found?(name, search_dirs)
      name
    end
    return if missing.empty?
    raise "missing static libraries: #{missing.map { "lib#{_1}.a" }.join(", ")}"
  end

  def library_archive_found?(name, search_dirs)
    search_dirs.any? { File.exist?(File.join(_1, "lib#{name}.a")) }
  end

  def render_c_template(symbol)
    template = File.read(File.join(root, "build", "main.c"))
    template.gsub("__MRUBY_LLM_IREP_SYMBOL__", symbol)
  end
end
