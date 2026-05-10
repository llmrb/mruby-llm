# frozen_string_literal: true

describe "LLM::Context" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:provider) { LLM.openai(key: "test-key", transport:) }
  let(:params) { {} }
  let(:ctx) { LLM::Context.new(provider, params) }

  context "when given a thread of messages" do
    let(:params) { {model: "gpt-4.1"} }
    let(:messages) { ctx.messages }
    let(:msg) { messages.to_a[-1] }
    let(:system_prompt) { "Keep your answers short and concise" }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk system_prompt
        _1.talk "Say hello"
      end
    end

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions.json")
      ctx.talk(prompt)
    end

    it "provides a response" do
      expect(msg.role).must_equal "assistant"
      expect(msg.content).must_equal "Hello from fixture"
    end

    it "provides an Enumerator" do
      expect(messages.each).must_be_instance_of Enumerator
    end

    it "provides a message at an index" do
      0.upto(2) { |i| expect(messages[i]).must_be_instance_of LLM::Message }
    end

    it "returns nil when an index is out of bounds" do
      expect(messages[3]).must_be_nil
    end

    it "provides the last message" do
      expect(messages.last).must_equal messages.to_a[-1]
    end
  end

  context "when given an IO stream" do
    let(:stream) { StringIO.new }
    let(:params) { {model: "gpt-4.1", stream:} }
    let(:system_prompt) { "Keep your answers short and concise" }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk system_prompt
        _1.talk "Say hello there"
      end
    end

    before do
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions.sse",
        headers: {"content-type" => "text/event-stream"}
      )
      ctx.talk(prompt)
    end

    it "streams text into the IO" do
      expect(stream.string).must_equal "Hello there"
    end

    it "stores the streamed assistant message" do
      expect(ctx.messages.find(&:assistant?).content).must_equal "Hello there"
    end

    it "stores usage on the assistant message" do
      usage = ctx.messages.find(&:assistant?)&.usage
      expect(usage.input_tokens).must_equal 4
      expect(usage.output_tokens).must_equal 2
      expect(usage.total_tokens).must_equal 6
    end
  end

  context "when given a tool call" do
    let(:tool) do
      Class.new(LLM::Tool) do
        name "system"
        description "Runs system commands"
        parameter :command, String, "The command to run"
        required %i[command]

        def call(command:)
          {"success" => command == "date" ? "2025-08-24" : false}
        end
      end
    end
    let(:params) { {model: "gpt-4.1", tools: [tool]} }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk "You are a bot that can run UNIX system commands"
        _1.talk "Hey, run the 'date' command"
      end
    end

    before do
      transport
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool.json")
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool_result.json")
      ctx.talk(prompt)
    end

    it "exposes pending functions" do
      expect(ctx.functions.empty?).must_equal false
    end

    it "calls the function" do
      ctx.talk ctx.functions[0].call
      expect(ctx.functions).must_be_empty
    end

    it "calls the functions" do
      ctx.talk ctx.functions.map(&:call)
      expect(ctx.functions).must_be_empty
    end

    it "includes a message with a return value" do
      ctx.talk ctx.functions.map(&:call)
      expect(ctx.messages.select(&:tool_return?).size).must_equal 1
    end

    it "returns the final assistant answer after the tool loop" do
      res = ctx.talk ctx.functions.map(&:call)
      expect(res.content).must_equal "Today's date is August 24, 2025."
      expect(ctx.messages.last.content).must_equal "Today's date is August 24, 2025."
    end
  end

  context "when given a streamed tool call" do
    let(:tool) do
      Class.new(LLM::Tool) do
        name "system"
        description "Runs system commands"
        parameter :command, String, "The command to run"
        required %i[command]

        def call(command:)
          {"success" => command == "date" ? "2025-08-24" : false}
        end
      end
    end
    let(:params) { {model: "gpt-4.1", stream: true, tools: [tool]} }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk "You are a bot that can run UNIX system commands"
        _1.talk "Hey, run the 'date' command"
      end
    end

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
      ctx.talk(prompt)
    end

    it "calls the function(s)" do
      res = ctx.talk ctx.functions.map(&:call)
      expect(ctx.functions).must_be_empty
      expect(res.content).must_equal "Today's date is August 24, 2025."
      expect(ctx.messages.last.content).must_equal "Today's date is August 24, 2025."
    end
  end
end

Minitest.run(ARGV) || exit(1)
