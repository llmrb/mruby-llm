# frozen_string_literal: true

describe "LLM::OpenAI provider integration" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.openai(key: "test-key", transport:) }

  context "when completing without streaming" do
    let(:res) { llm.complete("Hello") }
    let(:request) do
      res
      transport.requests[0]
    end
    let(:payload) { LLM.json.load(request[:body]) }

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions.json")
    end

    it "sends the expected request" do
      expect(request[:method]).must_equal "POST"
      expect(request[:path]).must_equal "/v1/chat/completions"
      expect(request[:headers]["authorization"]).must_equal "Bearer test-key"
      expect(payload["model"]).must_equal "gpt-4.1"
      expect(payload["messages"]).must_equal([
        {"role" => "user", "content" => [{"type" => "text", "text" => "Hello"}]}
      ])
    end

    it "adapts the fixture response" do
      expect(res.content).must_equal "Hello from fixture"
      expect(res.reasoning_content).must_equal "Think first"
      expect(res.model).must_equal "gpt-4.1"
      expect(res.input_tokens).must_equal 4
      expect(res.output_tokens).must_equal 5
      expect(res.reasoning_tokens).must_equal 2
    end
  end

  context "when completing with streaming" do
    let(:stream_class) do
      Class.new(LLM::Stream) do
        attr_reader :content, :reasoning_content

        def initialize
          @content = +""
          @reasoning_content = +""
        end

        def on_content(value)
          @content << value
        end

        def on_reasoning_content(value)
          @reasoning_content << value
        end
      end
    end

    let(:stream) { stream_class.new }
    let(:res) { llm.complete("Hello", stream:) }
    let(:request) do
      res
      transport.requests[0]
    end
    let(:payload) { LLM.json.load(request[:body]) }

    before do
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions.sse",
        headers: {"content-type" => "text/event-stream"}
      )
    end

    it "marks the request as streaming" do
      expect(payload["stream"]).must_equal true
      expect(payload["stream_options"]).must_equal({"include_usage" => true})
    end

    it "streams content and adapts the final response" do
      expect(res.content).must_equal "Hello there"
      expect(res.reasoning_content).must_equal "Think"
      expect(res.total_tokens).must_equal 6
      expect(res.reasoning_tokens).must_equal 1
      expect(stream.content).must_equal "Hello there"
      expect(stream.reasoning_content).must_equal "Think"
    end
  end
end

Minitest.run(ARGV) || exit(1)
