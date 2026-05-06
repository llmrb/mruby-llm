# frozen_string_literal: true

class LLM::Google
  ##
  # @private
  module RequestAdapter

    ##
    # @param [Array<LLM::Message>] messages
    #  The messages to adapt
    # @return [Array<Hash>]
    def adapt(messages, mode: nil)
      messages.filter_map do |message|
        Completion.new(message).adapt
      end
    end

    private

    ##
    # @param [Hash] params
    # @return [Hash]
    def adapt_schema(params)
      return {} unless params and params[:schema]
      schema = params.delete(:schema)
      schema = schema.respond_to?(:object) ? schema.object : schema
      {generationConfig: {response_mime_type: "application/json", response_schema: schema}}
    end

    ##
    # @param [Hash] params
    # @return [Hash]
    def adapt_tools(tools)
      return {} unless tools&.any?
      functions = tools.grep(LLM::Function)
      return {} if functions.empty?
      {tools: [{functionDeclarations: functions.map { _1.adapt(self) }}]}
    end
  end
end

LLM::Google.include(LLM::Google::RequestAdapter)
