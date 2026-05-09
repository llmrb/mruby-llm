# frozen_string_literal: true

describe "LLM::Buffer" do
  let(:provider) { LLM.openai(key: "test") }
  let(:buffer) { LLM::Buffer.new(provider) }

  describe "#rindex" do
    before do
      buffer << LLM::Message.new("user", "first")
      buffer << LLM::Message.new("assistant", "second")
      buffer << LLM::Message.new("user", "third")
    end

    it "returns the last matching index" do
      expect(buffer.rindex(&:user?)).must_equal 2
    end

    it "returns nil when no message matches" do
      expect(buffer.rindex(&:system?)).must_be_nil
    end
  end
end

Minitest.run(ARGV)
