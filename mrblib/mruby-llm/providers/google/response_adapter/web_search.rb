# frozen_string_literal: true

module LLM::Google::ResponseAdapter
  ##
  # The {LLM::Google::ResponseAdapter::WebSearch LLM::Google::ResponseAdapter::WebSearch}
  # module provides methods for accessing web search results from a web search
  # tool call made via the {LLM::Provider#web_search LLM::Provider#web_search}
  # method.
  module WebSearch
    ##
    # Returns one or more search results
    # @return [Array<LLM::Object>]
    def search_results
      LLM::Object.from(
        candidates[0]
          .groundingMetadata
          .groundingChunks
          .map { {"url" => _1.web.uri, "title" => _1.web.title} }
      )
    end
  end
end
