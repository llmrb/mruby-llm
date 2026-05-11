<p align="center">
  <a href="https://github.com/llmrb/llm.rb"><img src="https://github.com/llmrb/llm.rb/raw/main/llm.png" width="200" height="200" border="0" alt="mruby-llm"></a>
</p>
<p align="center">
  <a href="https://opensource.org/license/0bsd"><img src="https://img.shields.io/badge/License-0BSD-orange.svg?" alt="License"></a>
  <a href="https://github.com/llmrb/llm.rb/tags"><img src="https://img.shields.io/badge/version-8.0.0-green.svg?" alt="Version"></a>
</p>

## About

mruby-llm is mruby's most capable AI runtime.

It brings a single runtime for providers, agents, tools, skills, MCP,
streaming, files, and persisted state to mruby in a form that can be
embedded into small standalone applications. The project began as
a fork of [llm.rb](https://github.com/llmrb/llm.rb), and a large
number of features turned out to be portable. Both projects generally
improve each other and code continues to flow both ways.

There is support for OpenAI, Anthropic, Google Gemini, DeepSeek, xAI, Z.ai,
Ollama, and llama.cpp. The mruby port keeps the same overall execution
model as llm.rb, but adapts it to mruby constraints. There's still quite
a lot of the original llm.rb runtime that is supported though. 

## Quick start

#### LLM::Context

The
[LLM::Context](https://0x1eef.github.io/x/mruby-llm/LLM/Context.html)
object is at the heart of the runtime. Almost all other features build
on top of it. It is a low-level interface to a model, and requires tool
execution to be managed manually. The
[LLM::Agent](https://0x1eef.github.io/x/mruby-llm/LLM/Agent.html)
class is almost the same as
[LLM::Context](https://0x1eef.github.io/x/mruby-llm/LLM/Context.html),
but it manages tool execution for you:

```ruby
llm = LLM.openai(key: ENV["OPENAI_SECRET"])
ctx = LLM::Context.new(llm, stream: $stdout)
ctx.talk("Hello world")
```

#### LLM::Agent

The
[LLM::Agent](https://0x1eef.github.io/x/mruby-llm/LLM/Agent.html)
object is implemented on top of
[LLM::Context](https://0x1eef.github.io/x/mruby-llm/LLM/Context.html).
It provides the same interface, but manages tool execution for you. It
also includes loop guards that detect repeated tool-call patterns and
advise the model to change course rather than raise an error:

```ruby
llm = LLM.openai(key: ENV["OPENAI_SECRET"])
agent = LLM::Agent.new(llm, stream: $stdout)
agent.talk("Hello world")
```

#### Tools

The
[LLM::Tool](https://0x1eef.github.io/x/mruby-llm/LLM/Tool.html)
class can be subclassed to implement your own tools that extend the
abilities of a model:

```ruby
class ReadFile < LLM::Tool
  name "read-file"
  description "Read a file"
  parameter :path, String, "The filename or path"
  required %i[path]

  def call(path:)
    {contents: File.read(path)}
  end
end
```

#### MCP

The
[LLM::MCP](https://0x1eef.github.io/x/mruby-llm/LLM/MCP.html)
object lets mruby-llm use tools provided by an MCP server. Those tools
are exposed through the same runtime as local tools, so you can pass
them to either
[LLM::Context](https://0x1eef.github.io/x/mruby-llm/LLM/Context.html)
or
[LLM::Agent](https://0x1eef.github.io/x/mruby-llm/LLM/Agent.html):

```ruby
llm = LLM.openai(key: ENV["OPENAI_SECRET"])
mcp = LLM::MCP.stdio(argv: ["ruby", "server.rb"])

mcp.run do
  ctx = LLM::Context.new(llm, stream: $stdout, tools: mcp.tools)
  ctx.talk("Use the available tools to inspect the environment.")
  ctx.talk(ctx.call(:functions)) until ctx.functions.empty?
end
```

#### Skills

Skills are reusable instructions loaded from a `SKILL.md` directory.
They let you package behavior and tool access together, and they plug
into the same runtime as tools, agents, and MCP:

```yaml
---
name: release
description: Prepare a release
tools: ["read-file"]
---

## Task

Review the release state and summarize what changed.
```

```ruby
class ReleaseAgent < LLM::Agent
  model "gpt-4.1-mini"
  skills "./skills/release"
end
```

## Integration

Add to your mruby build config:

```ruby
MRuby::Build.new("app") do |conf|
  curldir = File.expand_path(ENV["CURLDIR"] || "/usr/local")
  conf.toolchain

  conf.cc.include_paths << File.join(curldir, "include")
  conf.linker.library_paths << File.join(curldir, "lib")

  conf.gembox "default"
  conf.gem github: "llmrb/mruby-llm", branch: "main"
  conf.enable_debug
end
```

Then build through your mruby checkout:

```sh
ruby minirake MRUBY_CONFIG=/absolute/path/to/build_config.rb
```

Dependencies are declared in [mrbgem.rake](mrbgem.rake). In practice the
main external build requirement is `libcurl`, because the runtime depends on
`mruby-curl` and `mruby-http`.

## Dependencies

Declared mrbgem dependencies include:

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
