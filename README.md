<p align="center">
  <a href="https://github.com/llmrb/llm.rb"><img src="https://github.com/llmrb/llm.rb/raw/main/llm.png" width="200" height="200" border="0" alt="mruby-llm"></a>
</p>
<p align="center">
  <a href="https://opensource.org/license/0bsd"><img src="https://img.shields.io/badge/License-0BSD-orange.svg?" alt="License"></a>
  <a href="https://github.com/llmrb/llm.rb/tags"><img src="https://img.shields.io/badge/version-8.0.0-green.svg?" alt="Version"></a>
</p>

## About

mruby-llm is a fork of Ruby's most capable AI runtime - [llm.rb](https://github.com/llmrb/llm.rb)
and it brings the same functionality to mruby. It keeps the same execution model
and most of the same features but adapted for mruby. Core runtime features are
supported, including multiple providers,
[`LLM::Context`](https://0x1eef.github.io/x/llm.rb/LLM/Context.html),
[`LLM::Agent`](https://0x1eef.github.io/x/llm.rb/LLM/Agent.html),
tools, skills, MCP, streaming, schemas, files, and persistence.

## Features

- Multi-provider chat built on the `llm.rb` execution model
- Stateful conversations with [`LLM::Context`](https://0x1eef.github.io/x/llm.rb/LLM/Context.html)
- Higher-level orchestration with [`LLM::Agent`](https://0x1eef.github.io/x/llm.rb/LLM/Agent.html)
- Prompt composition with `LLM::Prompt` and `LLM::Buffer`
- Structured outputs and schemas with `LLM::Schema`
- Streaming responses
- Local tool calling
- Skills
- Context transformers
- Loop guards with `LLM::LoopGuard`
- Context compaction
- Save and restore state from disk
- MCP over stdio
- MCP over HTTP
- MCP tools inside [`LLM::Context`](https://0x1eef.github.io/x/llm.rb/LLM/Context.html)

## Binaries

To produce a real native executable from a Ruby entrypoint, use the binary
tasks. You can find [repl.rb](repl.rb) in the repository as a working example.

### Dynamic

For a dynamically linked executable:

```sh
rake "build:dynamic:binary[repl.rb,repl]"
```

The dynamic task:

- compiles the input Ruby file to embedded mruby bytecode with `mrbc`
- generates a small C entrypoint
- links a native executable against the built mruby libraries
- writes the result to `bin/<output>`

Examples:

```sh
rake "build:dynamic:binary[repl.rb,repl]"
DEEPSEEK_SECRET=... bin/repl
```

```sh
rake "build:dynamic:binary[foo.rb,foo]"
bin/foo
```

To build against a specific curl install, set `CURLDIR`:

```sh
CURLDIR=/path/to/curl-prefix rake build:toolchain
CURLDIR=/path/to/curl-prefix rake "build:dynamic:binary[repl.rb,repl]"
```

### Static

For a statically linked executable:

```sh
rake "build:static:binary[repl.rb,repl]"
```

This adds `-static` at link time and depends on your toolchain and system
libraries supporting static linking.

To download and build a minimal static curl for mruby-llm:

```sh
CURLDIR=/path/to/curl-prefix rake build:curl
```

Override the release or tarball URL if needed:

```sh
CURL_VERSION=8.19.0 CURLDIR=/path/to/curl-prefix rake build:curl
CURL_URL=https://curl.se/download/curl-8.19.0.tar.xz CURLDIR=/path/to/curl-prefix rake build:curl
```

That curl build is intentionally trimmed for mruby-llm's HTTP use case:

- HTTP and HTTPS only
- OpenSSL TLS
- no SSH, brotli, PSL, IDN2, HTTP/2, or zstd
- static library output

After that, point the build at the curl prefix:

```sh
CURLDIR=/path/to/curl-prefix rake build:toolchain
CURLDIR=/path/to/curl-prefix rake "build:static:binary[repl.rb,repl]"
```

## Test

The standard flow is:

1. Build with `rake build:toolchain` or `ruby minirake`.
2. Run the built `mruby` binary against a small runtime check.

For example:

```sh
rake build:toolchain
bin/mruby -e 'p LLM::VERSION'
bin/mirb
```

## Runtime Dependencies

The mruby build uses:

- `mruby-http`
- `mruby-curl`
- `mruby-json`
- `mruby-stringio`
- `mruby-process`
- `mruby-enumerator`
- `mruby-io`
- `mruby-time`
- `mruby-env`
- `mruby-struct`
- `mruby-regexp`

See [mrbgem.rake](mrbgem.rake) and
[build_config/mruby-llm.rb](build_config/mruby-llm.rb).

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
