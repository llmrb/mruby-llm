# frozen_string_literal: true

describe "LLM::Function" do
  context "when calling a zero-argument tool" do
    let(:tool_class) do
      Class.new(LLM::Tool) do
        name "list-jails"
        description "List the available FreeBSD jails"

        def call
          [{name: "web", jid: 1}]
        end
      end
    end

    let(:function) do
      tool_class.new.function.tap do |fn|
        fn.id = "call_1"
        fn.arguments = {}
      end
    end

    it "invokes the tool without splatting empty keyword arguments" do
      ret = function.call
      expect(ret.id).must_equal "call_1"
      expect(ret.name).must_equal "list-jails"
      expect(ret.value).must_equal([{name: "web", jid: 1}])
    end
  end
end

Minitest.run(ARGV) || exit(1)
