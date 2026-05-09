# frozen_string_literal: true

describe "LLM::Stream" do
  let(:stream) { LLM::Stream.new }
  let(:tool) do
    LLM::Function.new("system").tap do |fn|
      fn.id = "call_1"
      fn.arguments = {"command" => "date"}
    end
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
      expect(stream.on_tool_return(tool, stream.tool_not_found(tool))).must_be_nil
    end
  end

  describe "#tool_not_found" do
    it "returns an in-band error" do
      expect(stream.tool_not_found(tool).to_h).must_equal(
        id: "call_1", name: "system",
        value: {error: true, type: "LLM::NoSuchToolError", message: "tool not found"}
      )
    end

    it "marks the return as an error" do
      expect(stream.tool_not_found(tool).error?).must_equal true
    end
  end

  describe "LLM::Function::Return#error?" do
    it "returns true for automatic error returns" do
      result = LLM::Stream.new.tool_not_found(tool)
      expect(result.error?).must_equal true
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
end

Minitest.run(ARGV) || exit(1)
