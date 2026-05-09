# frozen_string_literal: true

describe "LLM::Message" do
  let(:image_url) { LLM::Object.from(value: "https://example.com/cat.png", kind: :image_url) }
  let(:local_file) { LLM::Object.from(value: LLM.File(__FILE__), kind: :local_file) }
  let(:remote_file) do
    LLM::Object.from(value: LLM::Object.from("id" => "file_123"), kind: :remote_file)
  end

  describe "#reasoning_content" do
    let(:msg) do
      LLM::Message.new("assistant", "answer", reasoning_content: "thought")
    end

    it "returns the reasoning content" do
      expect(msg.reasoning_content).must_equal "thought"
    end

    it "includes reasoning content in the hash representation" do
      expect(msg.to_h[:reasoning_content]).must_equal "thought"
    end
  end

  describe "#to_h" do
    let(:msg) do
      LLM::Message.new(
        "assistant",
        nil,
        reasoning_content: "thought",
        tool_calls: [LLM::Object.from("id" => "call_1")]
      )
    end

    it "preserves nil content" do
      expect(msg.to_h[:content]).must_be_nil
    end

    it "normalizes tool calls to hashes" do
      expect(msg.to_h[:tools]).must_equal [{"id" => "call_1"}]
    end
  end

  describe "#image_url?" do
    let(:msg) { LLM::Message.new("user", content) }

    context "when the message contains an image_url" do
      let(:content) { [image_url, local_file] }

      it "returns true" do
        expect(msg.image_url?).must_equal true
      end
    end

    context "when the message does not contain an image_url" do
      let(:content) { [local_file, remote_file] }

      it "returns false" do
        expect(msg.image_url?).must_equal false
      end
    end
  end

  describe "#image_urls" do
    let(:msg) { LLM::Message.new("user", [image_url, local_file]) }

    it "returns image_url content items" do
      expect(msg.image_urls).must_equal [image_url]
    end
  end

  describe "#file?" do
    let(:msg) { LLM::Message.new("user", content) }

    context "when the message contains a local file" do
      let(:content) { [local_file] }

      it "returns true" do
        expect(msg.file?).must_equal true
      end
    end

    context "when the message contains a remote file" do
      let(:content) { [remote_file] }

      it "returns true" do
        expect(msg.file?).must_equal true
      end
    end

    context "when the message does not contain a file" do
      let(:content) { [image_url] }

      it "returns false" do
        expect(msg.file?).must_equal false
      end
    end
  end

  describe "#files" do
    let(:msg) { LLM::Message.new("user", [image_url, local_file, remote_file]) }

    it "returns local and remote file content items" do
      expect(msg.files).must_equal [local_file, remote_file]
    end
  end
end

Minitest.run(ARGV) || exit(1)
