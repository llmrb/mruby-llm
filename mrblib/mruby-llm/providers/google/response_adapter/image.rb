# frozen_string_literal: true

module LLM::Google::ResponseAdapter
  module Image
    ##
    # @return [Array<StringIO>]
    def images
      (body.predictions || []).map do
        b64 = _1["bytesBase64Encoded"]
        StringIO.new(b64.unpack1("m0"))
      end
    end

    ##
    # Returns one or more image URLs, or an empty array
    # @note
    #  Gemini's image generation API does not return URLs, so this method
    #  will always return an empty array.
    # @return [Array<String>]
    def urls = []
  end
end
