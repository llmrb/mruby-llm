# frozen_string_literal: true

describe "LLM::OpenAI tool integration" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.openai(key: "test-key", transport:) }
  let(:tool) do
    LLM.function(:system) do |fn|
      fn.name "system"
      fn.description "Runs system commands"
      fn.params do |schema|
        schema.object(command: schema.string.required)
      end
    end
  end

  context "when completing with tools" do
    let(:res) { llm.complete("What is the date?", tools: [tool]) }
    let(:request) do
      res
      transport.requests[0]
    end
    let(:payload) { LLM.json.load(request[:body]) }
    let(:msg) { res.messages[0] }
    let(:function) { msg.functions[0] }

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool.json")
    end

    it "includes the tool in the request" do
      expect(payload["tools"].length).must_equal(1)
      expect(payload["tools"][0]["function"]["name"]).must_equal("system")
    end

    it "returns a tool-call assistant message" do
      expect(msg.tool_call?).must_equal(true)
      expect(msg.content).must_be_nil
      expect(msg.functions.size).must_equal(1)
    end

    it "resolves the returned tool call" do
      expect(function.id).must_equal("call_SlEPR82Y3H6rDkdney2ZxXFU")
      expect(function.name).must_equal("system")
      expect(function.arguments.to_h).must_equal({"command" => "date"})
    end
  end

  context "when streaming a tool call" do
    let(:stream_class) do
      Class.new(LLM::Stream) do
        attr_reader :calls

        def initialize
          @calls = []
        end

        def on_tool_call(fn, error)
          @calls << [fn, error]
        end
      end
    end

    let(:stream) { stream_class.new }
    let(:res) { llm.complete("What is the date?", tools: [tool], stream:) }
    let(:call) do
      res
      stream.calls[0]
    end
    let(:function) { call[0] }

    before do
      stream.extra[:tools] = [tool]
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions_tool.sse",
        headers: {"content-type" => "text/event-stream"}
      )
    end

    it "emits the resolved tool call through the stream" do
      expect(function).must_be_instance_of LLM::Function
      expect(function.id).must_equal("call_SlEPR82Y3H6rDkdney2ZxXFU")
      expect(function.name).must_equal("system")
      expect(function.arguments.to_h).must_equal({"command" => "date"})
      expect(call[1]).must_be_nil
    end

    it "returns a streamed tool-call assistant message" do
      expect(res.messages[0].tool_call?).must_equal(true)
      expect(res.total_tokens).must_equal(18)
    end
  end
end

Minitest.run(ARGV) || exit(1)
