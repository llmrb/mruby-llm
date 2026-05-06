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

## Integration

`mruby-llm` is an [`mrbgem`](https://mruby.org/docs/guides/mrbgems.html).

Add it to your own mruby build config. A typical consumer build looks like:

```ruby
MRuby::Build.new("app") do |conf|
  conf.toolchain
  conf.gembox "default"
  conf.enable_debug

  conf.cc.include_paths << "/usr/local/include"
  conf.linker.library_paths << "/usr/local/lib"

  conf.gem "/absolute/path/to/mruby-llm"

  conf.enable_bintest
  conf.enable_test
end
```

Then build through your mruby checkout:

```sh
ruby minirake MRUBY_CONFIG=/absolute/path/to/build_config.rb
```

`mruby-llm` pulls in its own mrbgem dependencies through
[mrbgem.rake](mrbgem.rake), so the consumer build config only needs to:

- choose the mruby toolchain
- set any include and library paths needed for `libcurl`
- include `mruby-llm`
- define any application-specific binaries or extra gems

Consumer projects are expected to own their own build configuration, toolchain
choices, and executable packaging.

## Runtime Dependencies

The gem depends on:

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

See [mrbgem.rake](mrbgem.rake).

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
