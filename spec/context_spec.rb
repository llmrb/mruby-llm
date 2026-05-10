# frozen_string_literal: true

describe "LLM::Context" do
  let(:fixtures_root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { SpecSupport::FixtureTransport.new(root: fixtures_root) }
  let(:provider) { LLM.openai(key: "test-key", transport: transport) }
  let(:ctx) { LLM::Context.new(provider, model: "gpt-4.1", tools: [system]) }
  let(:system) do
    Class.new(LLM::Tool) do
      name "system"
      description "Runs system commands"
      params do |schema|
        schema.object(command: schema.string.required)
      end

      def call(command:)
        {"success" => command == "date" ? "2025-08-24" : false}
      end
    end
  end

  context "when completing a tool call with a real tool subclass" do
    let(:first_response) { ctx.talk("What is the date?") }
    let(:function) do
      first_response
      ctx.functions.fetch(0)
    end
    let(:result) do
      first_response
      ctx.call(:functions).fetch(0)
    end
    let(:second_response) { ctx.talk([result]) }
    let(:first_request) { LLM.json.load(transport.requests.fetch(0)[:body]) }
    let(:second_request) { LLM.json.load(transport.requests.fetch(1)[:body]) }

    before do
      transport
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool.json")
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool_result.json")
    end

    it "returns a tool-call assistant message on the first turn" do
      message = first_response.messages.fetch(0)
      expect(message.tool_call?).must_equal true
      expect(message.to_h[:tools].map { _1.merge(arguments: _1[:arguments].to_h) }).must_equal([
        {id: "call_SlEPR82Y3H6rDkdney2ZxXFU", name: "system", arguments: {"command" => "date"}}
      ])
    end

    it "serializes the tool definition on the first request" do
      first_response
      expect(first_request["tools"]).must_equal([
        {
          "type" => "function",
          "name" => "system",
          "function" => {
            "name" => "system",
            "description" => "Runs system commands",
            "parameters" => {
              "type" => "object",
              "properties" => {
                "command" => {"type" => "string"}
              },
              "required" => ["command"]
            }
          }
        }
      ])
    end

    it "resolves the pending function against the real tool subclass" do
      expect(function.id).must_equal "call_SlEPR82Y3H6rDkdney2ZxXFU"
      expect(function.name).must_equal "system"
      expect(function.arguments.to_h).must_equal({"command" => "date"})
      expect(result.to_h).must_equal(
        id: "call_SlEPR82Y3H6rDkdney2ZxXFU",
        name: "system",
        value: {"success" => "2025-08-24"}
      )
    end

    it "replays the tool call and tool return on the second request" do
      second_response
      expect(second_request["messages"].fetch(1)).must_equal(
        {
          "role" => "assistant",
          "content" => nil,
          "tool_calls" => [
            {
              "id" => "call_SlEPR82Y3H6rDkdney2ZxXFU",
              "type" => "function",
              "function" => {
                "name" => "system",
                "arguments" => "{\"command\":\"date\"}"
              }
            }
          ]
        }
      )
      expect(second_request["messages"].fetch(2)).must_equal(
        {
          "role" => "tool",
          "tool_call_id" => "call_SlEPR82Y3H6rDkdney2ZxXFU",
          "content" => "{\"success\":\"2025-08-24\"}"
        }
      )
    end

    it "returns the recorded final assistant response on the second turn" do
      expect(second_response.content).must_equal "Today's date is August 24, 2025."
      expect(second_response.total_tokens).must_equal 100
      expect(ctx.messages.last.content).must_equal "Today's date is August 24, 2025."
    end
  end
end

Minitest.run(ARGV) || exit(1)
