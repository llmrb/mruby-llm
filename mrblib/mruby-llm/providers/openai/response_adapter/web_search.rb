# frozen_string_literal: true

module LLM::OpenAI::ResponseAdapter
  ##
  # The {LLM::OpenAI::ResponseAdapter::WebSearch LLM::OpenAI::ResponseAdapter::WebSearch}
  # module provides methods for accessing web search results from a web search
  # tool call made via the {LLM::Provider#web_search LLM::Provider#web_search}
  # method.
  module WebSearch
    ##
    # Returns one or more search results
    # @return [Array<LLM::Object>]
    def search_results
      LLM::Object.from(
        choices[0]
          .annotations
          .map { _1.slice(:title, :url) }
      )
    end
  end
end
