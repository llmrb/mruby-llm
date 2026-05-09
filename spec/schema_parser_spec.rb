# frozen_string_literal: true

describe "LLM::Schema.parse" do
  let(:parsed) { LLM::Schema.parse(schema) }

  context "when given an object schema" do
    let(:schema) do
      {
        type: "object",
        description: "person",
        properties: {
          name: {type: "string", description: "name"},
          tags: {
            type: "array",
            items: {type: "string", minLength: 2}
          }
        },
        required: ["name"]
      }
    end

    it "returns an object schema" do
      expect(parsed).must_be_instance_of LLM::Schema::Object
    end

    it "parses nested properties" do
      expect(parsed["name"]).must_be_instance_of LLM::Schema::String
      expect(parsed["name"].description).must_equal "name"
    end

    it "marks required properties" do
      expect(parsed["name"].required?).must_equal true
      expect(parsed["tags"].required?).must_equal false
    end

    it "parses nested array items" do
      array = parsed["tags"]
      expect(array).must_be_instance_of LLM::Schema::Array
      expect(array.to_h[:type]).must_equal "array"
      expect(array.to_h[:items]).must_equal LLM::Schema.new.string.min(2)
    end
  end

  context "when given an array schema" do
    let(:schema) do
      {
        type: "array",
        description: "directories",
        items: {
          type: "object",
          properties: {
            path: {type: "string"},
            size: {type: "integer", minimum: 0}
          },
          required: ["path"]
        }
      }
    end

    let(:item) { parsed.to_h[:items] }

    it "returns an array schema" do
      expect(parsed).must_be_instance_of LLM::Schema::Array
    end

    it "parses the array metadata" do
      expect(parsed.to_h[:description]).must_equal "directories"
      expect(parsed.to_h[:type]).must_equal "array"
    end

    it "parses item schemas recursively" do
      expect(item).must_be_instance_of LLM::Schema::Object
      expect(item.keys).must_equal ["path", "size"]
      expect(item["path"].required?).must_equal true
      expect(item["path"]).must_equal LLM::Schema.new.string
      expect(item["size"]).must_equal LLM::Schema.new.integer.min(0)
    end
  end

  context "when given an anyOf union" do
    let(:schema) do
      {
        anyOf: [
          {type: "string", minLength: 1},
          {type: "array", items: {type: "string"}}
        ],
        description: "input"
      }
    end

    it "returns an anyOf schema" do
      expect(parsed).must_be_instance_of LLM::Schema::AnyOf
    end

    it "parses each branch recursively" do
      expect(parsed.to_h).must_equal(
        description: "input",
        anyOf: [
          LLM::Schema.new.string.min(1),
          LLM::Schema.new.array(LLM::Schema.new.string)
        ]
      )
    end
  end

  context "when given a type array union" do
    let(:schema) do
      {
        type: ["object", "null"],
        description: "maybe object",
        properties: {
          id: {type: "string"}
        },
        required: ["id"]
      }
    end

    it "returns an anyOf schema" do
      expect(parsed).must_be_instance_of LLM::Schema::AnyOf
    end

    it "parses each branch recursively" do
      expect(parsed.to_h).must_equal(
        description: "maybe object",
        anyOf: [
          LLM::Schema.new.object("id" => LLM::Schema.new.string.required),
          LLM::Schema.new.null
        ]
      )
    end
  end

  context "when type is omitted but const implies a primitive" do
    let(:schema) do
      {
        const: "workspace",
        description: "kind"
      }
    end

    it "infers the primitive type" do
      expect(parsed).must_equal(
        LLM::Schema.new.string.const("workspace").description("kind")
      )
    end
  end

  context "when given scalar metadata" do
    let(:schema) do
      {
        type: "number",
        description: "ratio",
        default: 1,
        enum: [1, 2],
        minimum: 0,
        maximum: 10
      }
    end

    it "applies metadata to the parsed leaf" do
      expect(parsed.to_h).must_equal(
        description: "ratio",
        default: 1,
        enum: [1, 2],
        type: "number",
        minimum: 0,
        maximum: 10
      )
    end
  end

  context "when given local refs" do
    let(:schema) do
      {
        type: "object",
        properties: {
          owner: {type: "string", description: "owner"},
          collaborator: {"$ref" => "#/properties/owner", description: "collaborator"}
        },
        required: ["collaborator"]
      }
    end

    it "resolves the ref against the root schema" do
      expect(parsed["collaborator"]).must_be_instance_of LLM::Schema::String
      expect(parsed["collaborator"].description).must_equal "collaborator"
      expect(parsed["collaborator"].required?).must_equal true
    end
  end

  context "when given an unsupported schema type" do
    let(:schema) { {type: "nope"} }

    it "raises a type error" do
      expect(proc { parsed }).must_raise TypeError
    end
  end
end

Minitest.run(ARGV) || exit(1)
