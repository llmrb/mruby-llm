# frozen_string_literal: true

describe "provider response adapters" do
  describe "LLM::OpenAI::ResponseAdapter::Completion" do
    let(:adapter_class) do
      Class.new do
        include LLM::OpenAI::ResponseAdapter::Completion
        attr_reader :body
        def initialize(body)
          @body = body
        end
      end
    end
    let(:body) { LLM::Object.new }
    let(:adapter) { adapter_class.new(body) }

    it "returns an empty message list when choices are absent" do
      expect(adapter.messages).must_equal []
    end
  end

  describe "LLM::Anthropic::ResponseAdapter::Completion" do
    let(:adapter_class) do
      Class.new do
        include LLM::Anthropic::ResponseAdapter::Completion
        attr_reader :body
        def initialize(body)
          @body = body
        end
        def role
          body.role
        end
      end
    end
    let(:body) do
      LLM::Object.from(
        "role" => "assistant",
        "content" => [
          {
            "type" => "tool_use",
            "id" => "toolu_1",
            "name" => "list-jails",
            "input" => {}
          }
        ]
      )
    end
    let(:adapter) { adapter_class.new(body) }
    let(:result_message) { adapter.messages[0] }
    let(:tool_call) { result_message.extra.tool_calls[0] }

    it "builds an assistant message for tool-only content" do
      expect(result_message.role).must_equal "assistant"
      expect(result_message.content).must_equal ""
      expect(tool_call.id).must_equal "toolu_1"
      expect(tool_call.name).must_equal "list-jails"
      expect(tool_call.arguments.to_h).must_equal({})
    end
  end

  describe "LLM::Google::ResponseAdapter::Completion" do
    let(:adapter_class) do
      Class.new do
        include LLM::Google::ResponseAdapter::Completion
        attr_reader :body
        def initialize(body)
          @body = body
        end
      end
    end
    let(:body) do
      LLM::Object.from(
        "candidates" => [
          {
            "content" => {
              "role" => "model",
              "parts" => [
                {"text" => "Listing"},
                {"functionCall" => {"name" => "list-jails", "args" => {}}},
                {"text" => " complete"}
              ]
            }
          }
        ]
      )
    end
    let(:adapter) { adapter_class.new(body) }
    let(:result_message) { adapter.messages[0] }
    let(:tool_call) { result_message.extra.tool_calls[0] }

    it "adapts function calls without relying on chained enumerators" do
      expect(result_message.role).must_equal "model"
      expect(result_message.content).must_equal "Listing complete"
      expect(tool_call.id).must_equal "google_call_0_1"
      expect(tool_call.name).must_equal "list-jails"
      expect(tool_call.arguments.to_h).must_equal({})
    end
  end
end

Minitest.run(ARGV) || exit(1)
