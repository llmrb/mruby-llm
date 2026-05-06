# frozen_string_literal: true

module LLM::Google::ResponseAdapter
  module Models
    include LLM::Model::Collection

    private

    def raw_models
      body.models || []
    end
  end
end
