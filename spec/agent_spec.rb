# frozen_string_literal: true

describe "LLM::Agent" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.openai(key: "test-key", transport:) }

  let(:schema) do
    Class.new(LLM::Schema) do
      property :answer, LLM::Schema::String, "answer", required: true
    end
  end

  let(:tool) { LLM::Function.new("echo") }

  describe ".new" do
    context "when configured with class-level defaults" do
      let(:skill_dir) { File.join(root, "skills", "temp-skill") }
      let(:agent_class) do
        configured_schema = schema
        configured_tool = tool
        configured_skill_dir = skill_dir
        Class.new(LLM::Agent) do
          model "gpt-4.1-mini"
          schema configured_schema
          tools configured_tool
          skills configured_skill_dir
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "applies the class-level model" do
        expect(agent.model).must_equal "gpt-4.1-mini"
      end

      it "applies the class-level schema" do
        expect(agent.params[:schema]).must_equal schema
      end

      it "applies the class-level tool" do
        expect(agent.params[:tools].first).must_equal tool
      end

      it "applies the class-level skill" do
        expect(agent.params[:tools].last.name).must_equal "temp-skill"
      end
    end

    context "when model is declared with a block" do
      let(:agent_class) do
        Class.new(LLM::Agent) do
          def configured_model
            llm.default_model
          end

          model { configured_model }
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "resolves the block against the agent instance" do
        expect(agent.model).must_equal "gpt-4.1"
      end
    end

    context "when no model is configured" do
      let(:agent) { LLM::Agent.new(llm) }

      it "keeps the provider default model" do
        expect(agent.model).must_equal "gpt-4.1"
      end
    end

    context "when tools are declared with a block" do
      let(:agent_class) do
        configured_tool = tool
        Class.new(LLM::Agent) do
          define_method(:configured_tools) { [configured_tool] }
          tools { configured_tools }
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "resolves the block against the agent instance" do
        expect(agent.params[:tools].first).must_equal tool
      end
    end

    context "when skills are declared with a block" do
      let(:skill_dir) { File.join(root, "skills", "temp-skill") }
      let(:agent_class) do
        configured_skill_dir = skill_dir
        Class.new(LLM::Agent) do
          define_method(:configured_skills) { [configured_skill_dir] }
          skills { configured_skills }
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "resolves the block against the agent instance" do
        expect(agent.params[:tools].first.name).must_equal "temp-skill"
      end
    end

    context "when schema is declared with a block" do
      let(:agent_class) do
        configured_schema = schema
        Class.new(LLM::Agent) do
          define_method(:configured_schema) { configured_schema }
          schema { configured_schema }
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "resolves the block against the agent instance" do
        expect(agent.params[:schema]).must_equal schema
      end
    end

    context "when configured with a tracer block" do
      let(:tracer) { Object.new }
      let(:agent_class) do
        configured_tracer = tracer
        Class.new(LLM::Agent) do
          define_method(:configured_tracer) { configured_tracer }
          tracer { configured_tracer }
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "resolves the tracer without mutating the provider default" do
        expect(agent.tracer).must_equal tracer
      end

      it "keeps the provider default tracer intact" do
        expect(llm.tracer).must_be_instance_of LLM::Tracer::Null
      end
    end

    context "when configured with a stream block" do
      let(:agent_class) do
        Class.new(LLM::Agent) do
          stream { StringIO.new }
        end
      end
      let(:first_agent) { agent_class.new(llm) }
      let(:second_agent) { agent_class.new(llm) }

      it "creates a separate stream per agent instance" do
        expect(first_agent.stream == second_agent.stream).must_equal false
      end

      it "uses the configured stream type" do
        expect(first_agent.stream).must_be_instance_of StringIO
      end
    end

    context "when configured with a stream object" do
      let(:stream) { StringIO.new }
      let(:agent_class) do
        configured_stream = stream
        Class.new(LLM::Agent) do
          stream configured_stream
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "passes the stream to the context" do
        expect(agent.stream).must_equal stream
      end
    end

    context "when given proc overrides at initialization" do
      let(:default_tool) { LLM::Function.new("default-tool") }
      let(:override_tool) { LLM::Function.new("override-tool") }
      let(:default_schema) do
        Class.new(LLM::Schema) do
          property :value, LLM::Schema::String, "value", required: true
        end
      end
      let(:override_schema) do
        Class.new(LLM::Schema) do
          property :count, LLM::Schema::Integer, "count", required: true
        end
      end
      let(:default_tracer) { Object.new }
      let(:override_tracer) { Object.new }
      let(:skill_dir) { File.join(root, "skills", "override-skill") }
      let(:agent_class) do
        configured_schema = default_schema
        configured_tracer = default_tracer
        configured_tool = default_tool
        Class.new(LLM::Agent) do
          model "gpt-4.1-mini"
          schema configured_schema
          tracer configured_tracer
          tools configured_tool
        end
      end
      let(:agent) do
        configured_schema = override_schema
        configured_tracer = override_tracer
        configured_tool = override_tool
        configured_skill_dir = skill_dir
        agent_class.new(
          llm,
          model: proc { "gpt-4.1" },
          schema: proc { configured_schema },
          tracer: proc { configured_tracer },
          tools: proc { [configured_tool] },
          skills: proc { configured_skill_dir }
        )
      end

      it "resolves the model override proc" do
        expect(agent.model).must_equal "gpt-4.1"
      end

      it "resolves the schema override proc" do
        expect(agent.params[:schema]).must_equal override_schema
      end

      it "resolves the tracer override proc" do
        expect(agent.tracer).must_equal override_tracer
      end

      it "resolves the tools override proc" do
        expect(agent.params[:tools].first).must_equal override_tool
      end

      it "resolves the skills override proc" do
        expect(agent.params[:tools].last.name).must_equal "override-skill"
      end
    end

    context "when configured with class-level concurrency" do
      let(:agent_class) do
        Class.new(LLM::Agent) do
          concurrency :call
        end
      end
      let(:agent) { agent_class.new(llm) }

      it "keeps concurrency on the agent" do
        expect(agent.concurrency).must_equal :call
      end
    end
  end

  describe "#talk" do
    context "when configured with a class-level stream object" do
      let(:stream) { StringIO.new }
      let(:agent_class) do
        configured_stream = stream
        Class.new(LLM::Agent) do
          stream configured_stream
        end
      end
      let(:agent) { agent_class.new(llm, model: "gpt-4.1") }

      before do
        transport.stub(
          "POST", "/v1/chat/completions",
          fixture: "openai/chat_completions.sse",
          headers: {"content-type" => "text/event-stream"}
        )
        agent.talk("Say hello")
      end

      it "writes the response to the configured stream" do
        expect(stream.string).must_equal "Hello there"
      end
    end

    context "when given a stream override at initialization" do
      let(:default_stream) { StringIO.new }
      let(:override_stream) { StringIO.new }
      let(:agent_class) do
        configured_stream = default_stream
        Class.new(LLM::Agent) do
          stream configured_stream
        end
      end
      let(:agent) { agent_class.new(llm, model: "gpt-4.1", stream: override_stream) }

      before do
        transport.stub(
          "POST", "/v1/chat/completions",
          fixture: "openai/chat_completions.sse",
          headers: {"content-type" => "text/event-stream"}
        )
        agent.talk("Say hello")
      end

      it "prefers the instance stream over the class-level stream" do
        expect(override_stream.string).must_equal "Hello there"
      end

      it "does not write to the class-level stream" do
        expect(default_stream.string).must_equal ""
      end
    end

    context "when auto-executing streamed tool calls" do
      let(:stream) do
        Class.new(LLM::Stream) do
          attr_reader :returns
          def initialize
            @returns = []
          end
          def on_tool_return(tool, result)
            @returns << [tool.name, result.name, result.value]
          end
        end.new
      end
      let(:tool) do
        Class.new(LLM::Tool) do
          name "system"
          parameter :command, String, "The command"
          required %i[command]
          def call(command:)
            {"success" => command == "date" ? "2025-08-24" : false}
          end
        end
      end
      let(:agent) { LLM::Agent.new(llm, model: "gpt-4.1", stream:, tools: [tool]) }

      before do
        transport
          .stub(
            "POST", "/v1/chat/completions",
            fixture: "openai/chat_completions_tool.sse",
            headers: {"content-type" => "text/event-stream"}
          )
          .stub(
            "POST", "/v1/chat/completions",
            fixture: "openai/chat_completions_tool_result.sse",
            headers: {"content-type" => "text/event-stream"}
          )
        agent.talk("Run date")
      end

      it "emits tool returns without manual stream queueing" do
        expect(stream.returns).must_equal [["system", "system", {"success" => "2025-08-24"}]]
      end
    end

    context "when confirming streamed tool calls" do
      let(:stream) do
        Class.new(LLM::Stream) do
          attr_reader :returns
          def initialize
            @returns = []
          end
          def on_tool_return(tool, result)
            @returns << [tool.name, result.name, result.value]
          end
        end.new
      end
      let(:tool) do
        calls = self.calls
        Class.new(LLM::Tool) do
          name "system"
          parameter :command, String, "The command"
          required %i[command]
          define_method(:call) do |command:|
            calls << command
            {"success" => command == "date" ? "2025-08-24" : false}
          end
        end
      end
      let(:calls) { [] }
      let(:agent_class) do
        Class.new(LLM::Agent) do
          confirm "system"
          def on_tool_confirmation(fn, strategy)
            fn.spawn(strategy).wait
          end
        end
      end
      let(:agent) { agent_class.new(llm, model: "gpt-4.1", stream:, tools: [tool]) }

      before do
        transport
          .stub(
            "POST", "/v1/chat/completions",
            fixture: "openai/chat_completions_tool.sse",
            headers: {"content-type" => "text/event-stream"}
          )
          .stub(
            "POST", "/v1/chat/completions",
            fixture: "openai/chat_completions_tool_result.sse",
            headers: {"content-type" => "text/event-stream"}
          )
        agent.talk("Run date")
      end

      it "emits confirmed tool returns" do
        expect(stream.returns).must_equal [["system", "system", {"success" => "2025-08-24"}]]
      end

      it "executes the confirmed tool once" do
        expect(calls).must_equal ["date"]
      end
    end
  end
end

Minitest.run(ARGV) || exit(1)
