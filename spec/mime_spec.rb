# frozen_string_literal: true

describe "LLM::Mime" do
  describe ".[]" do
    it "returns the correct mime type for a file extension" do
      expect(LLM::Mime[".png"]).must_equal "image/png"
      expect(LLM::Mime[".jpg"]).must_equal "image/jpeg"
      expect(LLM::Mime[".mp4"]).must_equal "video/mp4"
      expect(LLM::Mime[".mp3"]).must_equal "audio/mpeg"
      expect(LLM::Mime[".pdf"]).must_equal "application/pdf"
      expect(LLM::Mime[".bin"]).must_equal "application/octet-stream"
    end

    it "returns the correct mime type for a file path" do
      expect(LLM::Mime["image.png"]).must_equal "image/png"
      expect(LLM::Mime["photo.jpg"]).must_equal "image/jpeg"
      expect(LLM::Mime["video.mp4"]).must_equal "video/mp4"
      expect(LLM::Mime["audio.mp3"]).must_equal "audio/mpeg"
      expect(LLM::Mime["program.bin"]).must_equal "application/octet-stream"
    end

    it "returns the correct mime type for an object with a path method" do
      file = Struct.new(:path).new("picture.png")
      expect(LLM::Mime[file]).must_equal "image/png"

      file = Struct.new(:path).new("movie.mp4")
      expect(LLM::Mime[file]).must_equal "video/mp4"

      file = Struct.new(:path).new("song.mp3")
      expect(LLM::Mime[file]).must_equal "audio/mpeg"

      file = Struct.new(:path).new("report.pdf")
      expect(LLM::Mime[file]).must_equal "application/pdf"

      file = Struct.new(:path).new("program.bin")
      expect(LLM::Mime[file]).must_equal "application/octet-stream"
    end
  end

  describe ".types" do
    let(:types) { LLM::Mime.types }

    it "includes common mime types" do
      expect(types[".png"]).must_equal "image/png"
      expect(types[".jpg"]).must_equal "image/jpeg"
      expect(types[".mp4"]).must_equal "video/mp4"
      expect(types[".mp3"]).must_equal "audio/mpeg"
    end
  end
end

Minitest.run(ARGV)
