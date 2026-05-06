# frozen_string_literal: true

require "fileutils"
require "rake/file_utils"

module Build::Curl
  extend self
  extend FileUtils
  extend RakeFileUtils

  DEFAULT_VERSION = "8.19.0"

  def root
    File.expand_path("..", __dir__)
  end

  def curldir
    File.expand_path(ENV["CURLDIR"] || File.join(root, "contrib", "curl"))
  end

  def version
    ENV["CURL_VERSION"] || DEFAULT_VERSION
  end

  def url
    ENV["CURL_URL"] || "https://curl.se/download/curl-#{version}.tar.xz"
  end

  def workdir
    File.join(root, "tmp", "curl")
  end

  def tarball
    File.join(workdir, File.basename(url))
  end

  def srcdir
    File.join(workdir, "src")
  end

  def curlsrc
    entries = Dir[File.join(srcdir, "curl-*")].select { File.directory?(_1) }
    raise "curl source not found under #{srcdir}" if entries.empty?
    entries.sort.last
  end

  def curlsrc?
    entries = Dir[File.join(srcdir, "curl-*")].select { File.directory?(_1) }
    !entries.empty?
  end

  def configure_args
    [
      "./configure",
      "--prefix=#{curldir}",
      "--enable-static",
      "--disable-shared",
      "--with-openssl",
      "--enable-http",
      "--disable-ftp",
      "--disable-file",
      "--disable-ldap",
      "--disable-ldaps",
      "--disable-rtsp",
      "--disable-dict",
      "--disable-telnet",
      "--disable-tftp",
      "--disable-pop3",
      "--disable-imap",
      "--disable-smb",
      "--disable-smtp",
      "--disable-gopher",
      "--disable-mqtt",
      "--disable-manual",
      "--disable-docs",
      "--disable-libcurl-option",
      "--disable-basic-auth",
      "--disable-bearer-auth",
      "--disable-digest-auth",
      "--disable-kerberos-auth",
      "--disable-negotiate-auth",
      "--disable-ntlm",
      "--disable-proxy",
      "--disable-cookies",
      "--disable-netrc",
      "--disable-alt-svc",
      "--disable-hsts",
      "--disable-ipv6",
      "--disable-threaded-resolver",
      "--disable-unix-sockets",
      "--without-brotli",
      "--without-libpsl",
      "--without-nghttp2",
      "--without-ngtcp2",
      "--without-zstd",
      "--without-libidn2",
      "--without-libssh2"
    ]
  end

  def fetch!
    mkdir_p(workdir)
    rm_f(tarball)
    rm_rf(srcdir)
    mkdir_p(srcdir)
    sh "fetch -o #{tarball} #{url}"
    sh "tar -C #{srcdir} -xf #{tarball}"
    puts "Fetched curl source into #{srcdir}"
  end

  def build!
    fetch! unless curlsrc?
    mkdir_p(curldir)
    Dir.chdir(curlsrc) do
      sh "make distclean >/dev/null 2>&1 || true"
      sh "env PKG_CONFIG_PATH=#{File.join(curldir, "lib", "pkgconfig")} CFLAGS='-Os' #{configure_args.join(" ")}"
      sh "make -j$(getconf NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)"
      sh "make install"
    end
    puts "Built minimal curl into #{curldir}"
  end
end

namespace :build do
  desc "Build a minimal static curl into CURLDIR from a downloaded tarball"
  task :curl => "build:curl:fetch" do
    Build::Curl.build!
  end

  namespace :curl do
    task :fetch do
      Build::Curl.fetch!
    end
  end
end
