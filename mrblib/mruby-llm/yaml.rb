# frozen_string_literal: true

module LLM
  module YAML
    def self.safe_load(string)
      result = {}
      lines = string.lines
      index = 0

      while index < lines.length
        line = lines[index]
        index += 1

        next if line.strip.empty?

        match = line.match(/\A\s*([^:]+):(?:\s*(.*))?\z/)
        raise ArgumentError, "Unsupported YAML frontmatter" unless match

        key = match[1].strip
        value = match[2]

        if value.nil? || value.empty?
          result[key] = parse_list(lines, index)
          index += result[key].length
        else
          result[key] = parse_value(value.strip)
        end
      end

      result
    end

    def self.parse_list(lines, index)
      items = []

      while index < lines.length
        line = lines[index]
        stripped = line.strip
        break if stripped.empty?

        match = line.match(/\A\s*-\s*(.*)\z/)
        break unless match

        items << parse_value(match[1].strip)
        index += 1
      end

      items
    end

    def self.parse_value(value)
      return [] if value == "[]"
      return parse_inline_array(value) if value.start_with?("[") && value.end_with?("]")
      return value[1..-2] if quoted?(value)
      return true if value == "true"
      return false if value == "false"
      return nil if value == "null"
      return value.to_i if value.match?(/\A-?\d+\z/)
      return value.to_f if value.match?(/\A-?\d+\.\d+\z/)

      value
    end

    def self.parse_inline_array(value)
      body = value[1..-2].strip
      return [] if body.empty?

      body.split(/\s*,\s*/).map { parse_value(_1) }
    end

    def self.quoted?(value)
      (value.start_with?('"') && value.end_with?('"')) ||
        (value.start_with?("'") && value.end_with?("'"))
    end
  end
end
