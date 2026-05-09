# frozen_string_literal: true

describe "LLM::OpenAI::StreamParser" do
  let(:stream) do
    Class.new(LLM::Stream) do
      attr_reader :content, :reasoning_content, :calls

      def initialize
        @content = +""
        @reasoning_content = +""
        @calls = []
      end

      def on_content(value)
        @content << value
      end

      def on_reasoning_content(value)
        @reasoning_content << value
      end

      def on_tool_call(fn, error)
        @calls << [fn, error]
      end

      def tool_not_found(fn)
        {id: fn.id, name: fn.name, value: {error: true}}
      end
    end.new
  end

  let(:parser) { LLM::OpenAI::StreamParser.new(stream) }

  before { LLM::Tool.clear_registry! }
  after { parser.free }

  context "when given streamed content and reasoning deltas" do
    before do
      parser.parse!("choices" => [{"index" => 0, "delta" => {"content" => +"Hel"}}])
      parser.parse!("choices" => [{"index" => 0, "delta" => {"content" => +"lo"}}])
      parser.parse!("choices" => [{"index" => 0, "delta" => {"reasoning_content" => +"Think"}}])
    end

    it "accumulates content into one message" do
      expect(parser.body.dig("choices", 0, "message", "content")).must_equal "Hello"
      expect(stream.content).must_equal "Hello"
    end

    it "accumulates reasoning content into one message" do
      expect(parser.body.dig("choices", 0, "message", "reasoning_content")).must_equal "Think"
      expect(stream.reasoning_content).must_equal "Think"
    end
  end

  context "when a streamed tool call becomes complete" do
    let(:first_chunk) do
      {"choices" => [{
        "index" => 0,
        "delta" => {"tool_calls" => [{
          "index" => 0,
          "id" => "call_1",
          "function" => {"name" => "missing", "arguments" => +"{\"command\""}
        }]}
      }]}
    end

    let(:second_chunk) do
      {"choices" => [{
        "index" => 0,
        "delta" => {"tool_calls" => [{
          "index" => 0,
          "function" => {"arguments" => +":\"date\"}"}
        }]}
      }]}
    end

    before do
      stream.extra[:tracer] = Object.new
      stream.extra[:model] = "deepseek-chat"
      parser.parse!(first_chunk)
      parser.parse!(second_chunk)
    end

    let(:call) { stream.calls.fetch(0) }
    let(:fn) { call.fetch(0) }
    let(:error) { call.fetch(1) }

    it "emits a function with the completed arguments" do
      expect(fn.id).must_equal "call_1"
      expect(fn.name).must_equal "missing"
      expect(fn.arguments).must_equal({"command" => "date"})
    end

    it "propagates tracer and model metadata" do
      expect(fn.tracer).must_equal stream.extra[:tracer]
      expect(fn.model).must_equal "deepseek-chat"
    end

    it "emits an in-band tool-not-found error" do
      expect(error).must_equal(id: "call_1", name: "missing", value: {error: true})
    end
  end
end

Minitest.run(ARGV) || exit(1)
