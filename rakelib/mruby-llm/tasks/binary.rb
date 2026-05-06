# frozen_string_literal: true

require "fileutils"
require "rake/file_utils"

module LLM
end

module LLM::Task
end

module LLM::Task::Binary
  extend self
  extend FileUtils
  extend RakeFileUtils

  def root
    File.expand_path("../../../", __dir__)
  end

  def mruby_dir
    File.expand_path(ENV["MRUBY_DIR"] || File.join(root, "..", "mruby"))
  end

  def config
    File.join(root, "build_config", "mruby-llm.rb")
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

  def build_runtime!
    ensure_mruby_checkout!
    source_bin = File.join(build_root, "bin")
    Dir.chdir(mruby_dir) do
      sh "ruby minirake clean"
      sh "ruby minirake MRUBY_CONFIG=#{config}"
    end
    rm_rf(bin_dir)
    mkdir_p(bin_dir)
    cp_r(Dir[File.join(source_bin, "*")], bin_dir)
    puts "Built binaries copied to #{bin_dir}"
  end

  def build(input:, output: nil)
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
    puts "Built native binary at #{target}"
  end

  def render_c_template(symbol)
    template = File.read(File.join(root, "rakelib", "binary.c"))
    template.gsub("__MRUBY_LLM_IREP_SYMBOL__", symbol)
  end
end
