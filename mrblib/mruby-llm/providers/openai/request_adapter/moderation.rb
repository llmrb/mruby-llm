# frozen_string_literal: true

module LLM::OpenAI::RequestAdapter
  ##
  # @private
  class Moderation
    ##
    # @param [String, URI, Array<String, URI>] inputs
    #  The inputs to format
    # @return [LLM::OpenAI::RequestAdapter::Moderation]
    def initialize(inputs)
      @inputs = inputs
    end

    ##
    # Adapts the inputs for the OpenAI moderations API
    # @return [Array<Hash>]
    def adapt
      [*inputs].flat_map do |input|
        if String === input
          {type: :text, text: input}
        elsif URI === input
          {type: :image_url, url: input.to_s}
        else
          raise LLM::FormatError, "The given object (an instance of #{input.class}) " \
                                  "is not supported by OpenAI moderations API"
        end
      end
    end

    private

    attr_reader :inputs
  end
end
