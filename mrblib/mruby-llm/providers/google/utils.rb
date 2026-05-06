# frozen_string_literal: true

class LLM::Google
  module Utils
    ##
    # Returns a stable internal tool-call ID for Gemini function calls.
    #
    # Gemini responses may omit a direct tool-call ID, but llm.rb expects one
    # for matching pending tool calls with tool returns across streaming and
    # normal completion flows.
    #
    # When Gemini provides a `thoughtSignature`, that value is used as the
    # basis for the ID. Otherwise the ID falls back to the candidate and part
    # indexes, which are stable within the response.
    #
    # @param part [Hash]
    #   A Gemini content part containing a `functionCall`.
    # @param cindex [Integer]
    #   The candidate index for the tool call.
    # @param pindex [Integer]
    #   The part index for the tool call within the candidate.
    # @return [String]
    #   Returns a stable internal tool-call ID.
    def tool_id(part:, cindex:, pindex:)
      signature = part["thoughtSignature"].to_s
      return "google_#{signature}" unless signature.empty?
      "google_call_#{cindex}_#{pindex}"
    end
  end
end

LLM::Google.extend(LLM::Google::Utils)
