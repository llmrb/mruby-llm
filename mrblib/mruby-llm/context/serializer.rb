# frozen_string_literal: true

class LLM::Context
  ##
  # @api private
  module Serializer
    private

    def serialize_message(message)
      h = message.to_h
      h[:content] = serialize_content(h[:content])
      h
    end

    def serialize_content(content)
      case content
      when Array
        content.map { serialize_content(_1) }
      when LLM::Object
        serialize_object(content)
      else
        content
      end
    end

    def serialize_object(object)
      case object.kind
      when :image_url
        {__llm_kind__: "image_url", value: object.value}
      when :local_file
        {__llm_kind__: "local_file", path: object.value.path}
      when :remote_file
        {__llm_kind__: "remote_file", value: serialize_remote_file(object.value)}
      else
        object.to_h
      end
    end

    def serialize_remote_file(file)
      {
        "file?" => file.respond_to?(:file?) ? file.file? : true,
        "id" => (file.id if file.respond_to?(:id)),
        "filename" => (file.filename if file.respond_to?(:filename)),
        "mime_type" => (file.mime_type if file.respond_to?(:mime_type)),
        "uri" => (file.uri if file.respond_to?(:uri)),
        "file_type" => (file.file_type if file.respond_to?(:file_type)),
        "name" => (file.name if file.respond_to?(:name)),
        "display_name" => (file.display_name if file.respond_to?(:display_name))
      }.compact
    end
  end

  include Serializer
end
