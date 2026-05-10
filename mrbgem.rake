MRuby::Gem::Specification.new('mruby-llm') do |spec|
  spec.license = '0BSD'
  spec.authors = '0x1eef'
  spec.version = '0.1.0.beta'
  spec.description = 'Ruby toolkit for multiple Large Language Models (LLMs)'

  spec.rbfiles = %w[
    mrblib/mruby-llm/monitor.rb
    mrblib/mruby-llm.rb
    mrblib/mruby-llm/yaml.rb
    mrblib/mruby-llm/uri/parsed.rb
    mrblib/mruby-llm/uri.rb
    mrblib/mruby-llm/transport/request.rb
    mrblib/mruby-llm/transport/response.rb
    mrblib/mruby-llm/error.rb
    mrblib/mruby-llm/hash.rb
    mrblib/mruby-llm/utils.rb
    mrblib/mruby-llm/json.rb
    mrblib/mruby-llm/version.rb
    mrblib/mruby-llm/cost.rb
    mrblib/mruby-llm/usage.rb
    mrblib/mruby-llm/object.rb
    mrblib/mruby-llm/object/builder.rb
    mrblib/mruby-llm/object/kernel.rb
    mrblib/mruby-llm/schema/version.rb
    mrblib/mruby-llm/schema/leaf.rb
    mrblib/mruby-llm/schema/string.rb
    mrblib/mruby-llm/schema/enum.rb
    mrblib/mruby-llm/schema/number.rb
    mrblib/mruby-llm/schema/integer.rb
    mrblib/mruby-llm/schema/boolean.rb
    mrblib/mruby-llm/schema/null.rb
    mrblib/mruby-llm/schema/array.rb
    mrblib/mruby-llm/schema/object.rb
    mrblib/mruby-llm/schema/all_of.rb
    mrblib/mruby-llm/schema/any_of.rb
    mrblib/mruby-llm/schema/one_of.rb
    mrblib/mruby-llm/schema/parser.rb
    mrblib/mruby-llm/schema.rb
    mrblib/mruby-llm/contract.rb
    mrblib/mruby-llm/contract/completion.rb
    mrblib/mruby-llm/registry.rb
    mrblib/mruby-llm/model.rb
    mrblib/mruby-llm/prompt.rb
    mrblib/mruby-llm/message.rb
    mrblib/mruby-llm/response.rb
    mrblib/mruby-llm/mime.rb
    mrblib/mruby-llm/multipart/enumerator_io.rb
    mrblib/mruby-llm/multipart.rb
    mrblib/mruby-llm/file.rb
    mrblib/mruby-llm/pipe.rb
    mrblib/mruby-llm/mcp/error.rb
    mrblib/mruby-llm/mcp/command.rb
    mrblib/mruby-llm/mcp/mailbox.rb
    mrblib/mruby-llm/mcp/router.rb
    mrblib/mruby-llm/mcp/rpc.rb
    mrblib/mruby-llm/mcp/transport/stdio.rb
    mrblib/mruby-llm/mcp/transport/http/event_handler.rb
    mrblib/mruby-llm/mcp/transport/http.rb
    mrblib/mruby-llm/mcp.rb
    mrblib/mruby-llm/compactor.rb
    mrblib/mruby-llm/buffer.rb
    mrblib/mruby-llm/function/registry.rb
    mrblib/mruby-llm/function/tracing.rb
    mrblib/mruby-llm/function/array.rb
    mrblib/mruby-llm/function.rb
    mrblib/mruby-llm/stream/queue.rb
    mrblib/mruby-llm/stream.rb
    mrblib/mruby-llm/eventstream/event.rb
    mrblib/mruby-llm/eventstream/parser.rb
    mrblib/mruby-llm/eventstream.rb
    mrblib/mruby-llm/eventhandler.rb
    mrblib/mruby-llm/tracer.rb
    mrblib/mruby-llm/tracer/null.rb
    mrblib/mruby-llm/provider.rb
    mrblib/mruby-llm/provider/transport.rb
    mrblib/mruby-llm/provider/transport/http.rb
    mrblib/mruby-llm/provider/transport/http/execution.rb
    mrblib/mruby-llm/provider/transport/http/interruptible.rb
    mrblib/mruby-llm/provider/transport/http/stream_decoder.rb
    mrblib/mruby-llm/agent.rb
    mrblib/mruby-llm/providers/anthropic.rb
    mrblib/mruby-llm/providers/anthropic/error_handler.rb
    mrblib/mruby-llm/providers/anthropic/files.rb
    mrblib/mruby-llm/providers/anthropic/models.rb
    mrblib/mruby-llm/providers/anthropic/request_adapter.rb
    mrblib/mruby-llm/providers/anthropic/request_adapter/completion.rb
    mrblib/mruby-llm/providers/anthropic/response_adapter.rb
    mrblib/mruby-llm/providers/anthropic/response_adapter/completion.rb
    mrblib/mruby-llm/providers/anthropic/response_adapter/enumerable.rb
    mrblib/mruby-llm/providers/anthropic/response_adapter/file.rb
    mrblib/mruby-llm/providers/anthropic/response_adapter/models.rb
    mrblib/mruby-llm/providers/anthropic/response_adapter/web_search.rb
    mrblib/mruby-llm/providers/anthropic/stream_parser.rb
    mrblib/mruby-llm/providers/anthropic/utils.rb
    mrblib/mruby-llm/providers/google.rb
    mrblib/mruby-llm/providers/google/request_adapter.rb
    mrblib/mruby-llm/providers/google/request_adapter/completion.rb
    mrblib/mruby-llm/providers/google/audio.rb
    mrblib/mruby-llm/providers/google/error_handler.rb
    mrblib/mruby-llm/providers/google/files.rb
    mrblib/mruby-llm/providers/google/images.rb
    mrblib/mruby-llm/providers/google/models.rb
    mrblib/mruby-llm/providers/google/response_adapter.rb
    mrblib/mruby-llm/providers/google/response_adapter/completion.rb
    mrblib/mruby-llm/providers/google/response_adapter/embedding.rb
    mrblib/mruby-llm/providers/google/response_adapter/file.rb
    mrblib/mruby-llm/providers/google/response_adapter/files.rb
    mrblib/mruby-llm/providers/google/response_adapter/image.rb
    mrblib/mruby-llm/providers/google/response_adapter/models.rb
    mrblib/mruby-llm/providers/google/response_adapter/web_search.rb
    mrblib/mruby-llm/providers/google/stream_parser.rb
    mrblib/mruby-llm/providers/google/utils.rb
    mrblib/mruby-llm/providers/ollama.rb
    mrblib/mruby-llm/providers/ollama/error_handler.rb
    mrblib/mruby-llm/providers/ollama/models.rb
    mrblib/mruby-llm/providers/ollama/request_adapter.rb
    mrblib/mruby-llm/providers/ollama/request_adapter/completion.rb
    mrblib/mruby-llm/providers/ollama/response_adapter.rb
    mrblib/mruby-llm/providers/ollama/response_adapter/completion.rb
    mrblib/mruby-llm/providers/ollama/response_adapter/embedding.rb
    mrblib/mruby-llm/providers/ollama/response_adapter/models.rb
    mrblib/mruby-llm/providers/ollama/stream_parser.rb
    mrblib/mruby-llm/providers/openai.rb
    mrblib/mruby-llm/providers/openai/audio.rb
    mrblib/mruby-llm/providers/openai/error_handler.rb
    mrblib/mruby-llm/providers/openai/files.rb
    mrblib/mruby-llm/providers/openai/images.rb
    mrblib/mruby-llm/providers/openai/models.rb
    mrblib/mruby-llm/providers/openai/moderations.rb
    mrblib/mruby-llm/providers/openai/request_adapter.rb
    mrblib/mruby-llm/providers/openai/request_adapter/completion.rb
    mrblib/mruby-llm/providers/openai/request_adapter/moderation.rb
    mrblib/mruby-llm/providers/openai/request_adapter/respond.rb
    mrblib/mruby-llm/providers/openai/responses.rb
    mrblib/mruby-llm/providers/openai/responses/stream_parser.rb
    mrblib/mruby-llm/providers/openai/response_adapter.rb
    mrblib/mruby-llm/providers/openai/response_adapter/audio.rb
    mrblib/mruby-llm/providers/openai/response_adapter/completion.rb
    mrblib/mruby-llm/providers/openai/response_adapter/embedding.rb
    mrblib/mruby-llm/providers/openai/response_adapter/enumerable.rb
    mrblib/mruby-llm/providers/openai/response_adapter/file.rb
    mrblib/mruby-llm/providers/openai/response_adapter/image.rb
    mrblib/mruby-llm/providers/openai/response_adapter/models.rb
    mrblib/mruby-llm/providers/openai/response_adapter/moderations.rb
    mrblib/mruby-llm/providers/openai/response_adapter/responds.rb
    mrblib/mruby-llm/providers/openai/response_adapter/web_search.rb
    mrblib/mruby-llm/providers/openai/stream_parser.rb
    mrblib/mruby-llm/providers/openai/vector_stores.rb
    mrblib/mruby-llm/providers/deepseek.rb
    mrblib/mruby-llm/providers/deepseek/request_adapter.rb
    mrblib/mruby-llm/providers/deepseek/request_adapter/completion.rb
    mrblib/mruby-llm/providers/llamacpp.rb
    mrblib/mruby-llm/providers/xai.rb
    mrblib/mruby-llm/providers/xai/images.rb
    mrblib/mruby-llm/providers/zai.rb
    mrblib/mruby-llm/context.rb
    mrblib/mruby-llm/context/deserializer.rb
    mrblib/mruby-llm/context/serializer.rb
    mrblib/mruby-llm/tool/param.rb
    mrblib/mruby-llm/tool.rb
    mrblib/mruby-llm/skill.rb
    mrblib/mruby-llm/loop_guard.rb
  ].map { File.expand_path(_1, __dir__) }

  if ENV["ENV"] == "TEST"
    spec.rbfiles.concat Dir[File.expand_path("spec/lib/**/*.rb", __dir__)].sort
  end

  # Dependencies
  spec.add_dependency 'mruby-http',       :github => 'mattn/mruby-http'
  spec.add_dependency 'mruby-curl',       :github => 'llmrb/mruby-curl'
  spec.add_dependency 'mruby-json',       :github => 'mattn/mruby-json'
  spec.add_dependency 'mruby-stringio',   :github => 'ksss/mruby-stringio'
  spec.add_dependency 'mruby-process',    :github => 'iij/mruby-process'
  spec.add_dependency 'mruby-enumerator'
  spec.add_dependency 'mruby-io'
  spec.add_dependency 'mruby-time'
  spec.add_dependency 'mruby-env'
  spec.add_dependency 'mruby-struct'
  spec.add_dependency 'mruby-regexp'
end
