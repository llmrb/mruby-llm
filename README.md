<p align="center">
  <a href="https://github.com/llmrb/llm.rb"><img src="https://github.com/llmrb/llm.rb/raw/main/llm.png" width="200" height="200" border="0" alt="mruby-llm"></a>
</p>
<p align="center">
  <a href="https://opensource.org/license/0bsd"><img src="https://img.shields.io/badge/License-0BSD-orange.svg?" alt="License"></a>
  <a href="https://github.com/llmrb/llm.rb/tags"><img src="https://img.shields.io/badge/version-8.0.0-green.svg?" alt="Version"></a>
</p>

## About

`mruby-llm` is an mruby runtime based on [llm.rb](https://github.com/llmrb/llm.rb)
with API docs at [0x1eef.github.io/x/llm.rb](https://0x1eef.github.io/x/llm.rb?rebuild=1).

It keeps the same execution model and most of the same features, adapted for
mruby. Core runtime features are supported, including providers,
[`LLM::Context`](https://0x1eef.github.io/x/llm.rb/LLM/Context.html),
[`LLM::Agent`](https://0x1eef.github.io/x/llm.rb/LLM/Agent.html), tools,
skills, MCP, streaming, schemas, files, and persistence.

## Status

The runtime supports:

- provider chat
- [`LLM::Agent`](https://0x1eef.github.io/x/llm.rb/LLM/Agent.html)
- [`LLM::Context`](https://0x1eef.github.io/x/llm.rb/LLM/Context.html)
- streaming
- local tool calls
- context save and restore
- MCP over stdio
- MCP over HTTP
- MCP tools inside `LLM::Context`

## Build

This project is an [`mrbgem`](https://mruby.org/docs/guides/mrbgems.html).

The simplest build flow from this repo is:

```sh
rake build
```

That task expects an mruby checkout at `../mruby` by default. To use a
different checkout:

```sh
MRUBY_DIR=/path/to/mruby rake build
```

The task runs through the host Ruby, builds mruby with
[build_config/mruby-llm.rb](build_config/mruby-llm.rb), and copies the built
binaries into `bin/`.

The equivalent direct `minirake` flow is:

```sh
cd /path/to/mruby
ruby minirake clean
ruby minirake MRUBY_CONFIG=/absolute/path/to/mruby-llm/build_config/mruby-llm.rb
```

On FreeBSD-like systems, the build config already adds `/usr/local/include` and
`/usr/local/lib` for `libcurl`.

## Test

The standard flow is:

1. Build with `rake build` or `ruby minirake`.
2. Run the built `mruby` binary against a small runtime check.

For example:

```sh
rake build
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

## Agent

[`LLM::Agent`](https://0x1eef.github.io/x/llm.rb/LLM/Agent.html) is available
as the higher-level wrapper over
[`LLM::Context`](https://0x1eef.github.io/x/llm.rb/LLM/Context.html).

It supports:

- class-level defaults for `model`, `tools`, `skills`, `schema`, and `instructions`
- automatic tool-loop execution during `talk` and `respond`
- context persistence through the wrapped context

In mruby, agent tool execution currently runs through the supported `:call`
strategy.

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
