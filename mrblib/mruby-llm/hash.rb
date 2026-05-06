# frozen_string_literal: true

module LLM::Hash
  def self.try_convert(value)
    return value if ::Hash === value
    return value.to_hash if value.respond_to?(:to_hash)
    return value.to_h if value.respond_to?(:to_h)
    nil
  end
end
