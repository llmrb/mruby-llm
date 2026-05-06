# frozen_string_literal: true

module LLM::Anthropic::ResponseAdapter
  ##
  # The {LLM::Anthropic::ResponseAdapter::WebSearch LLM::Anthropic::ResponseAdapter::WebSearch}
  # module provides methods for accessing web search results from a web search
  # tool call made via the {LLM::Provider#web_search LLM::Provider#web_search}
  # method.
  module WebSearch
    ##
    # Returns one or more search results
    # @return [Array<LLM::Object>]
    def search_results
      LLM::Object.from(
        content
          .select { _1["type"] == "web_search_tool_result" }
          .flat_map { |n| n.content.map { _1.slice(:title, :url) } }
      )
    end
  end
end
