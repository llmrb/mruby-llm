<p align="center">
  <a href="https://github.com/llmrb/llm.rb"><img src="https://github.com/llmrb/llm.rb/raw/main/llm.png" width="200" height="200" border="0" alt="mruby-llm"></a>
</p>
<p align="center">
  <a href="https://opensource.org/license/0bsd"><img src="https://img.shields.io/badge/License-0BSD-orange.svg?" alt="License"></a>
  <a href="https://github.com/llmrb/llm.rb/tags"><img src="https://img.shields.io/badge/version-8.0.0-green.svg?" alt="Version"></a>
</p>

## About

mruby-llm is mruby's most capable AI runtime.

It brings multi-provider chat, agents, tools, schemas, streaming,
file handling, and MCP to the mruby runtime in a form that can be
embedded into small standalone applications. The project began as
a fork of [llm.rb](https://github.com/llmrb/llm.rb), and a large
number of features turned out to be portable. 

## Features

- **Providers** <br>
  OpenAI, Anthropic, Google Gemini, Ollama, DeepSeek, llama.cpp, xAI, and Z.ai
- **Contexts** <br>
  Stateful conversations, message history, params, and execution state through `LLM::Context`
- **Messages & Buffers** <br>
  Lower-level conversation and prompt primitives with `LLM::Message` and `LLM::Buffer`
- **Agents** <br>
  Reusable assistants with instructions, tools, skills, schemas, and automatic tool-loop handling
- **Skills Support** <br>
  Directory-backed skills loaded from `SKILL.md`
- **Tool Calling** <br>
  Closure-based tools via `LLM.function` and class-based tools via `LLM::Tool`
- **Structured Output** <br>
  Schema-driven outputs through `LLM::Schema`
- **Runtime Objects** <br>
  Nested provider data and tool payloads through `LLM::Object`
- **Streaming** <br>
  Visible content, reasoning content, tool-call events, and queued tool returns
- **Files** <br>
  Local files, remote file references, mime lookup, and multipart request helpers
- **MCP Support** <br>
  Stdio and HTTP MCP transports with routing, mailbox handling, and tool bridging
- **Persistence** <br>
  Save and restore context state across runs
- **Context Compaction** <br>
  Summarize older history in long-lived contexts
- **Loop Guards** <br>
  Detect and stop repeated tool-call execution patterns
- **Tracing & Registries** <br>
  Runtime tracing hooks, provider registries, and local model metadata

## Example

```ruby
class Agent < LLM::Agent
  model "deepseek-v4"
  instructions "Use tools when they help."
  tools WeatherTool, CalendarTool
end

llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
agent = Agent.new(llm)
res = agent.talk("If Tokyo is warm this Saturday, plan a picnic and put it on my calendar.")
puts res.content
```

Or at the lower-level context surface:

```ruby
llm = LLM.openai(key: ENV["OPENAI_API_KEY"])
ctx = LLM::Context.new(llm, model: "gpt-4.1-mini")
res = ctx.talk("Return a haiku about FreeBSD.")
puts res.content
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

## Origins

### llm.rb

mruby-llm implements the same overall execution model as
[llm.rb](https://github.com/llmrb/llm.rb#readme):
providers, contexts, agents, tools, schemas, streaming, and MCP.
The mruby port keeps that surface where it makes sense, but adapts the
runtime to mruby constraints such as explicit builds, smaller standard
library surface, and a more modest concurrency story.

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
