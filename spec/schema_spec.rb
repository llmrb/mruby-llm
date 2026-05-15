# frozen_string_literal: true

describe "LLM::Schema" do
  context "when given a schema" do
    let(:all_properties) { [*required_properties, *unrequired_properties] }
    let(:required_properties) { ["name", "age", "height"] }
    let(:unrequired_properties) { ["active", "location", "addresses"] }

    let(:schema) do
      Class.new(LLM::Schema) do
        property :name, LLM::Schema::String, "name description", required: true
        property :age, LLM::Schema::Integer, "age description", required: true
        property :height, LLM::Schema::Number, "height description", required: true
        property :active, LLM::Schema::Boolean, "active description"
        property :location, LLM::Schema::Null, "location description"
        property :addresses, LLM::Schema::Array[LLM::Schema::String], "addresses description"
      end
    end

    it "has properties" do
      expect(schema.object.keys).must_equal all_properties
    end

    it "sets properties" do
      all_properties.each { expect(schema.object[_1].description).must_equal "#{_1} description" }
      required_properties.each { expect(schema.object[_1].required?).must_equal true }
      unrequired_properties.each { expect(schema.object[_1].required?).must_equal false }
    end

    it "configures an array" do
      array = schema.object["addresses"]
      builder = schema.schema
      expect(array).must_equal(
        builder.array(builder.string).description("addresses description")
      )
    end
  end

  context "when given a mixed Array[...] property type" do
    let(:schema) do
      Class.new(LLM::Schema) do
        property :values, Array[String, Integer], "mixed values", required: true
      end
    end

    context "when reading the values property" do
      let(:values) { schema.object["values"] }

      it "builds an array property" do
        expect(values).must_be_instance_of LLM::Schema::Array
      end

      it "preserves the description" do
        expect(values.description).must_equal "mixed values"
      end

      it "marks the property as required" do
        expect(values.required?).must_equal true
      end

      it "builds anyOf items" do
        expect(values.to_h[:items]).must_equal(
          LLM::Schema.new.any_of(LLM::Schema.new.string, LLM::Schema.new.integer)
        )
      end
    end
  end

  context "when given nested schema classes" do
    let(:address_schema) do
      Class.new(LLM::Schema) do
        property :street, String, "street description", required: true
      end
    end

    let(:person_schema) do
      address = address_schema
      Class.new(LLM::Schema) do
        property :name, String, "name description", required: true
        property :address, address, "address description", required: true
      end
    end

    context "when given the address" do
      let(:address) { person_schema.object["address"] }

      it "is configured properly" do
        expect(address).must_be_instance_of LLM::Schema::Object
        expect(address.description).must_equal "address description"
        expect(address.required?).must_equal true
        expect(address.keys).must_equal ["street"]
      end
    end

    context "when given the street" do
      let(:street) { person_schema.object["address"]["street"] }

      it "is configured properly" do
        expect(street).must_be_instance_of LLM::Schema::String
        expect(street.description).must_equal "street description"
        expect(street.required?).must_equal true
      end
    end

    it "requires certain keys" do
      object = person_schema.object
      expect(object.to_h[:required]).must_equal ["name", "address"]
      expect(object["address"].to_h[:required]).must_equal ["street"]
    end
  end

  context "when given a oneOf property type" do
    let(:schema) do
      eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
        class ResultSchema < LLM::Schema
          property :result, OneOf[String, Integer], "result description", required: true
        end
        ResultSchema
      RUBY
    end

    let(:result) { schema.object["result"] }

    it "configures the property as a oneOf union" do
      expect(result).must_be_instance_of LLM::Schema::OneOf
      expect(result.description).must_equal "result description"
      expect(result.required?).must_equal true
      expect(result.to_h[:oneOf].map(&:class)).must_equal [LLM::Schema::String, LLM::Schema::Integer]
    end
  end

  context "when given an anyOf property type" do
    let(:schema) do
      eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
        class AnyResultSchema < LLM::Schema
          property :result, AnyOf[String, Integer], "result description", required: true
        end
        AnyResultSchema
      RUBY
    end

    let(:result) { schema.object["result"] }

    it "configures the property as an anyOf union" do
      expect(result).must_be_instance_of LLM::Schema::AnyOf
      expect(result.description).must_equal "result description"
      expect(result.required?).must_equal true
      expect(result.to_h[:anyOf].map(&:class)).must_equal [LLM::Schema::String, LLM::Schema::Integer]
    end
  end

  context "when given an allOf property type" do
    let(:schema) do
      eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
        class AllResultSchema < LLM::Schema
          property :result, AllOf[String, Integer], "result description", required: true
        end
        AllResultSchema
      RUBY
    end

    let(:result) { schema.object["result"] }

    it "configures the property as an allOf union" do
      expect(result).must_be_instance_of LLM::Schema::AllOf
      expect(result.description).must_equal "result description"
      expect(result.required?).must_equal true
      expect(result.to_h[:allOf].map(&:class)).must_equal [LLM::Schema::String, LLM::Schema::Integer]
    end
  end
end

Minitest.run(ARGV) || exit(1)
