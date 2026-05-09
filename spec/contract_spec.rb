# frozen_string_literal: true

describe "LLM::Contract" do
  let(:contract) do
    Module.new do
      extend LLM::Contract

      def foo
      end

      def bar
      end
    end
  end

  context "when a module implements a contract" do
    let(:impl) do
      Module.new do
        def foo
        end

        def bar
        end
      end
    end

    it "does not raise an error" do
      expect { impl.include(contract) }.must_be_silent
    end
  end

  context "when a module does not implement all contract methods" do
    let(:impl) do
      Module.new do
        def foo
        end
      end
    end

    let(:error) { assert_raises(LLM::Contract::ContractError) { impl.include(contract) } }

    it "raises a ContractError" do
      expect(error.message).must_match "bar"
    end
  end
end

Minitest.run(ARGV) || exit(1)
