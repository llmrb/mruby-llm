<p align="center">
  <a href="mruby-llm"><img src="https://github.com/llmrb/llm.rb/raw/main/llm.png" width="200" height="200" border="0" alt="mruby-llm"></a>
</p>
<p align="center">
  <a href="https://opensource.org/license/0bsd"><img src="https://img.shields.io/badge/License-0BSD-orange.svg?" alt="License"></a>
  <a href="https://github.com/llmrb/llm.rb/tags"><img src="https://img.shields.io/badge/version-8.0.0-green.svg?" alt="Version"></a>
</p>

# mruby-llm

## About

`mruby-llm` is an mruby runtime based on [llm.rb](https://github.com/llmrb/llm.rb).
It keeps the same runtime model and most of the same features, but is designed
for mruby instead of CRuby.
<br>

The goal is not a thin compatibility shim. It is to keep the core
`llm.rb` runtime available under mruby: providers, `LLM::Context`,
`LLM::Agent`, tools, skills, MCP, streaming, schemas, files, and persistence.

The runtime surface in this repository lives under `mrblib/`.

## Status

The port is past the bootstrapping stage and now keeps all core features of the
runtime:

- provider chat
- `LLM::Agent`
- `LLM::Context`
- streaming
- local tool calls
- context save/restore
- MCP over stdio
- MCP over HTTP
- MCP tools inside `LLM::Context`

The current supported surface is documented in
[resources/mruby-support.md](resources/mruby-support.md).

## Build

This project is an `mrbgem`. Build it through an mruby checkout using
[build_config/mruby-llm.rb](build_config/mruby-llm.rb):

```sh
cd /path/to/mruby
ruby minirake MRUBY_CONFIG=/absolute/path/to/mruby-llm/build_config/mruby-llm.rb
```

On FreeBSD-like systems, the build config already adds `/usr/local/include` and
`/usr/local/lib` for `libcurl`.

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

See:

- [mrbgem.rake](mrbgem.rake)
- [build_config/mruby-llm.rb](build_config/mruby-llm.rb)

## Verification

The verified mruby surface is summarized in
[resources/mruby-support.md](resources/mruby-support.md).

## Agent

`LLM::Agent` is available in the mruby runtime as the higher-level wrapper over
`LLM::Context`.

It supports:

- class-level defaults for `model`, `tools`, `skills`, `schema`, and `instructions`
- automatic tool-loop execution during `talk` and `respond`
- context persistence through the wrapped context

In mruby, agent tool execution currently runs through the supported `:call`
strategy only.

## Scope

This project is mruby-first. It does not aim to preserve the CRuby
standard-library transport model, `net-http-persistent`, or server-tool surface
inside the mruby runtime.
