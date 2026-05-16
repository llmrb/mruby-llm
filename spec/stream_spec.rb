# frozen_string_literal: true

describe "LLM::Stream" do
  let(:stream) { LLM::Stream.new }
  let(:ctx) { LLM::Context.new(LLM.openai(key: "test"), model: "gpt-4.1") }
  let(:compactor) { LLM::Compactor.new(ctx) }
  let(:transformer) { Object.new }
  let(:tool) do
    LLM::Function.new("system").tap do |fn|
      fn.id = "call_1"
      fn.arguments = {"command" => "date"}
    end
  end
  let(:tool_error) do
    LLM::Function::Return.new("call_1", "system", {
      error: true, type: "LLM::NoSuchToolError", message: "tool not found"
    })
  end

  describe "#on_content" do
    it "returns nil" do
      expect(stream.on_content("hello")).must_be_nil
    end
  end

  describe "#<<" do
    it "aliases #on_content" do
      expect(stream << "hello").must_be_nil
    end
  end

  describe "#on_reasoning_content" do
    it "returns nil" do
      expect(stream.on_reasoning_content("think")).must_be_nil
    end
  end

  describe "#on_tool_call" do
    it "returns nil" do
      expect(stream.on_tool_call(tool, nil)).must_be_nil
    end
  end

  describe "#on_tool_return" do
    it "returns nil" do
      expect(stream.on_tool_return(tool, tool_error)).must_be_nil
    end
  end

  describe "#on_compaction" do
    it "returns nil" do
      expect(stream.on_compaction(ctx, compactor)).must_be_nil
    end
  end

  describe "#on_transform" do
    it "returns nil" do
      expect(stream.on_transform(ctx, transformer)).must_be_nil
    end
  end

  describe "#on_transform_finish" do
    it "returns nil" do
      expect(stream.on_transform_finish(ctx, transformer)).must_be_nil
    end
  end

  describe "#on_compaction_finish" do
    it "returns nil" do
      expect(stream.on_compaction_finish(ctx, compactor)).must_be_nil
    end
  end

  describe "LLM::Function::Return#error?" do
    it "returns true for tool errors" do
      expect(tool_error.error?).must_equal true
    end

    it "returns false for successful returns" do
      result = LLM::Function::Return.new("call_1", "system", {"ok" => true})
      expect(result.error?).must_equal false
    end
  end

  describe "#queue" do
    let(:queue) { stream.queue }

    it "returns a lazy queue" do
      expect(queue).must_be_instance_of LLM::Stream::Queue
      expect(queue).must_equal stream.queue
    end
  end

  describe "#wait" do
    before do
      stream.queue << tool_error
    end

    it "forwards to the queue" do
      expect(stream.wait(:call).map(&:to_h)).must_equal([
        {id: "call_1", name: "system", value: {error: true, type: "LLM::NoSuchToolError", message: "tool not found"}}
      ])
    end

    it "ignores strategy arguments when draining queued work" do
      expect(stream.wait(:thread).map(&:to_h)).must_equal([
        {id: "call_1", name: "system", value: {error: true, type: "LLM::NoSuchToolError", message: "tool not found"}}
      ])
    end
  end
end

Minitest.run(ARGV) || exit(1)
