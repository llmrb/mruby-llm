# frozen_string_literal: true

describe "LLM::Provider" do
  let(:provider_class) do
    Class.new(LLM::Provider) do
      def name
        :dummy
      end
      def complete(*)
        raise NotImplementedError
      end
      def embed(*)
        raise NotImplementedError
      end
    end
  end
  let(:transport) do
    Object.new.tap do |object|
      def object.inspect = "#<transport>"
      def object.request_owner = nil
      def object.interrupt!(*) = nil
    end
  end

  context "when the base path includes trailing slashes" do
    let(:provider) do
      provider_class.new(key: "test", host: "example.com", base_path: " /v1/// ", transport:)
    end

    it "normalizes the path without relying on String#sub" do
      expect(provider.send(:path, "/chat/completions")).must_equal "/v1/chat/completions"
    end
  end

  context "when the base path is the root path" do
    let(:provider) do
      provider_class.new(key: "test", host: "example.com", base_path: "/", transport:)
    end

    it "treats the base path as empty" do
      expect(provider.send(:path, "/chat/completions")).must_equal "/chat/completions"
    end
  end
end

Minitest.run(ARGV) || exit(1)
