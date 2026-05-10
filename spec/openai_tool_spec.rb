# frozen_string_literal: true

describe "LLM::OpenAI tool integration" do
  let(:fixtures_root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { SpecSupport::FixtureTransport.new(root: fixtures_root) }
  let(:llm) { LLM.openai(key: "test-key", transport: transport) }
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
    let(:response) { llm.complete("What is the date?", tools: [tool]) }
    let(:request) { transport.requests.fetch(0) }
    let(:payload) { LLM.json.load(request[:body]) }
    let(:msg) { response.messages.fetch(0) }
    let(:function) { msg.functions.fetch(0) }

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool.json")
    end

    it "serializes the tool definition in the request" do
      response
      expect(payload["tools"].length).must_equal(1)
      expect(payload["tools"].fetch(0)).must_equal(
        {
          "type" => "function",
          "name" => "system",
          "function" => {
            "name" => "system",
            "description" => "Runs system commands",
            "parameters" => {
              "type" => "object",
              "properties" => {
                "command" => {
                  "type" => "string"
                }
              },
              "required" => ["command"]
            }
          }
        }
      )
    end

    it "adapts the returned tool call" do
      expect(msg.tool_call?).must_equal(true)
      expect(msg.content).must_be_nil
      expect(msg.to_h[:tools].map { _1.merge(arguments: _1[:arguments].to_h) }).must_equal([
        {id: "call_SlEPR82Y3H6rDkdney2ZxXFU", name: "system", arguments: {"command" => "date"}}
      ])
    end

    it "resolves message functions against the request tools" do
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
    let(:response) { llm.complete("What is the date?", tools: [tool], stream: stream) }
    let(:call) { stream.calls.fetch(0) }
    let(:function) { call.fetch(0) }

    before do
      stream.extra[:tools] = [tool]
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions_tool.sse",
        headers: {"content-type" => "text/event-stream"}
      )
    end

    it "emits the resolved tool call through the stream" do
      response
      expect(function).must_be_instance_of LLM::Function
      expect(function.id).must_equal("call_SlEPR82Y3H6rDkdney2ZxXFU")
      expect(function.name).must_equal("system")
      expect(function.arguments.to_h).must_equal({"command" => "date"})
      expect(call.fetch(1)).must_be_nil
    end

    it "preserves the tool call on the adapted response" do
      response
      expect(response.messages.fetch(0).to_h[:tools].map { _1.merge(arguments: _1[:arguments].to_h) }).must_equal([
        {id: "call_SlEPR82Y3H6rDkdney2ZxXFU", name: "system", arguments: {"command" => "date"}}
      ])
      expect(response.total_tokens).must_equal(18)
    end
  end
end

Minitest.run(ARGV) || exit(1)
