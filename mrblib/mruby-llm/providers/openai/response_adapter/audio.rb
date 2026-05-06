# frozen_string_literal: true

module LLM::OpenAI::ResponseAdapter
  module Audio
    def audio = body.audio
  end
end
