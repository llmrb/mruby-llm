# frozen_string_literal: true

describe "LLM::Object" do
  describe ".from" do
    let(:obj) do
      LLM::Object.from(
        "user" => {
          "name" => "Ava",
          "tags" => ["a", {"k" => 1}]
        },
        "active" => true
      )
    end

    it "wraps nested hashes and arrays" do
      expect(obj).must_be_instance_of LLM::Object
      expect(obj.user).must_be_instance_of LLM::Object
      expect(obj.user.name).must_equal "Ava"
      expect(obj.user.tags[1]).must_be_instance_of LLM::Object
      expect(obj.user.tags[1].k).must_equal 1
    end
  end

  describe "key access" do
    let(:obj) { LLM::Object.from("foo" => "bar", :baz => 42) }

    it "provides indifferent access" do
      expect(obj["foo"]).must_equal "bar"
      expect(obj[:foo]).must_equal "bar"
      expect(obj["baz"]).must_equal 42
      expect(obj[:baz]).must_equal 42
    end

    it "provides method access" do
      expect(obj.foo).must_equal "bar"
      expect(obj.baz).must_equal 42
    end

    it "returns nil for missing keys" do
      expect(obj.nope).must_be_nil
      expect(obj["nope"]).must_be_nil
    end
  end

  describe "#[]=" do
    let(:obj) { LLM::Object.new }

    before { obj[:answer] = 42 }

    it "stores values using string keys" do
      expect(obj["answer"]).must_equal 42
      expect(obj.keys).must_equal ["answer"]
    end
  end

  describe "#transform_values!" do
    let(:obj) { LLM::Object.from("foo" => 1, "bar" => 2) }

    it "transforms values in place and returns the underlying hash" do
      expect(obj.transform_values! { |value| value * 10 }).must_equal("foo" => 10, "bar" => 20)
      expect(obj.to_h).must_equal("foo" => 10, "bar" => 20)
    end
  end

  describe "#to_h and #to_hash" do
    let(:obj) { LLM::Object.from("a" => 1, "b" => 2) }
    let(:h) { obj.to_h }
    let(:t) { obj.to_hash }

    it "returns a duplicate of the underlying hash" do
      expect(h).must_equal("a" => 1, "b" => 2)
      expect(t).must_equal(a: 1, b: 2)
      refute_same h, obj.to_h
    end
  end

  describe "#respond_to?" do
    let(:obj) { LLM::Object.from("foo" => "bar") }

    it "returns true for keys and methods" do
      expect(obj.respond_to?(:foo)).must_equal true
      expect(obj.respond_to?(:to_h)).must_equal true
    end
  end

  describe "#fetch" do
    let(:obj) { LLM::Object.from("foo" => "bar") }

    context "when the key exists" do
      it "returns the value for string keys" do
        expect(obj.fetch("foo")).must_equal "bar"
      end

      it "returns the value for symbol keys" do
        expect(obj.fetch(:foo)).must_equal "bar"
      end
    end

    context "when the key is missing" do
      it "raises KeyError" do
        expect(proc { obj.fetch("nope") }).must_raise KeyError
      end

      it "returns the default value when given" do
        expect(obj.fetch("nope", "default")).must_equal "default"
      end
    end

    it "reads fetch as an attribute when no argument is given" do
      obj.fetch = 123
      expect(obj.fetch).must_equal 123
    end
  end

  describe "#merge" do
    let(:obj) { LLM::Object.from("foo" => "bar") }

    it "returns a new object with merged values" do
      merged = obj.merge("baz" => 42)
      expect(merged).must_be_instance_of LLM::Object
      expect(merged.foo).must_equal "bar"
      expect(merged.baz).must_equal 42
      expect(obj.baz).must_be_nil
    end

    it "raises TypeError when the argument is not hash-like" do
      error = assert_raises(TypeError) { obj.merge(1) }
      expect(error.message).must_match "cannot be coerced into a Hash"
    end

    it "reads merge as an attribute when no argument is given" do
      obj.merge = 123
      expect(obj.merge).must_equal 123
    end
  end

  describe "#delete" do
    let(:obj) { LLM::Object.from("foo" => "bar", "baz" => 42) }

    it "deletes a key using indifferent access" do
      expect(obj.delete(:foo)).must_equal "bar"
      expect(obj.foo).must_be_nil
      expect(obj.keys).must_equal ["baz"]
    end

    it "still allows delete= as a dynamic attribute writer" do
      obj.delete = 123
      expect(obj["delete"]).must_equal 123
    end

    it "reads delete as an attribute when delete= assigned it" do
      obj.delete = 123
      expect(obj.delete).must_equal 123
    end
  end

  describe "built-in method names" do
    let(:obj) { LLM::Object.from("keys" => 123) }

    it "returns the underlying keys" do
      expect(obj.keys).must_equal ["keys"]
    end
  end

  describe "when given 'method_missing' as a key" do
    let(:obj) { LLM::Object.from("method_missing" => "bar", "foo" => "baz") }

    it "reads the stored method_missing value" do
      skip "pattern not supported by mruby"
      expect(obj.method_missing).must_equal "bar"
    end

    it "still reads other dynamic keys" do
      expect(obj.foo).must_equal "baz"
    end
  end

  describe "#key?" do
    let(:obj) { LLM::Object.from("key?" => 123) }

    it "reads key? as an attribute when no argument is given" do
      expect(obj.key?).must_equal 123
    end
  end

  describe "Enumerable" do
    let(:obj) { LLM::Object.from("a" => 1, "b" => 2, "c" => 3) }

    context "when iterating" do
      let(:pairs) do
        [].tap { |arr| obj.each { |k, v| arr << [k, v] } }
      end

      it "yields key-value pairs" do
        expect(pairs).must_equal [["a", 1], ["b", 2], ["c", 3]]
      end
    end

    context "when using enumerable helpers" do
      let(:mapped) { obj.map { |k, v| "#{k}=#{v}" } }
      let(:selected) { obj.select { |_, v| v.odd? } }

      it "supports map" do
        expect(mapped).must_equal ["a=1", "b=2", "c=3"]
      end

      it "supports select" do
        expect(selected).must_equal [["a", 1], ["c", 3]]
      end
    end
  end
end

Minitest.run(ARGV) || exit(1)
