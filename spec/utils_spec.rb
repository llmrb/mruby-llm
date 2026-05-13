# frozen_string_literal: true

describe "LLM::Utils" do
  describe ".rstrip" do
    it "removes trailing literal suffixes" do
      expect(LLM::Utils.rstrip("/v1///", "/")).must_equal "/v1"
    end

    it "preserves the root slash" do
      expect(LLM::Utils.rstrip("/", "/")).must_equal "/"
    end

    it "returns the input when the suffix is absent" do
      expect(LLM::Utils.rstrip("/v1", "/")).must_equal "/v1"
    end

    it "returns the input when the suffix is empty" do
      expect(LLM::Utils.rstrip("/v1/", "")).must_equal "/v1/"
    end
  end
end

Minitest.run(ARGV) || exit(1)
