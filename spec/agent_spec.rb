# frozen_string_literal: true

describe "LLM::Agent" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.openai(key: "test-key", transport:) }

  before do
    transport.stub(
      "POST", "/v1/chat/completions",
      fixture: "openai/chat_completions.sse",
      headers: {"content-type" => "text/event-stream"}
    )
  end

  context "when configured with a class-level stream object" do
    let(:stream) { StringIO.new }
    let(:agent_class) do
      configured_stream = stream
      Class.new(LLM::Agent) do
        self.stream(configured_stream)
      end
    end
    let(:agent) { agent_class.new(llm, model: "gpt-4.1") }

    it "uses the class-level stream" do
      agent.talk("Say hello")
      expect(stream.string).must_equal "Hello there"
    end
  end

  context "when configured with a class-level stream block" do
    let(:agent_class) do
      Class.new(LLM::Agent) do
        self.stream { StringIO.new }
      end
    end
    let(:agent) { agent_class.new(llm, model: "gpt-4.1") }

    it "evaluates the block during initialization" do
      agent.talk("Say hello")
      stream = agent.instance_variable_get(:@ctx).params[:stream]
      expect(stream).must_be_instance_of StringIO
      expect(stream.string).must_equal "Hello there"
    end
  end

  context "when given a stream override at initialization" do
    let(:default_stream) { StringIO.new }
    let(:override_stream) { StringIO.new }
    let(:agent_class) do
      configured_stream = default_stream
      Class.new(LLM::Agent) do
        self.stream(configured_stream)
      end
    end
    let(:agent) { agent_class.new(llm, model: "gpt-4.1", stream: override_stream) }

    it "prefers the instance stream over the class-level stream" do
      agent.talk("Say hello")
      expect(override_stream.string).must_equal "Hello there"
      expect(default_stream.string).must_equal ""
    end
  end
end

Minitest.run(ARGV) || exit(1)
