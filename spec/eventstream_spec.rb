# frozen_string_literal: true

describe "LLM::EventStream::Parser" do
  let(:stream_class) do
    Class.new(LLM::Stream) do
      attr_reader :content, :reasoning_content, :calls

      def initialize
        @content = +""
        @reasoning_content = +""
        @calls = []
      end

      def on_content(value)
        @content << value
      end

      def on_reasoning_content(value)
        @reasoning_content << value
      end

      def on_tool_call(fn, error)
        @calls << [fn, error]
      end
    end
  end

  let(:stream) { stream_class.new }
  let(:handler) { LLM::EventHandler.new(handler_parser.new(stream)) }
  let(:handler_parser) { LLM::OpenAI::StreamParser }
  let(:parser) do
    LLM::EventStream::Parser.new.tap do |instance|
      instance.register(handler)
    end
  end

  context "#<<" do
    context "when given a partial sse data line without a trailing newline" do
      let(:partial_line) { 'data: {"choices":[{"index":0,"delta":{"content":"He' }

      before do
        parser << partial_line
      end

      it "does not emit content to the stream" do
        expect(stream.content).must_equal ""
      end

      it "does not build a response body yet" do
        expect(handler.body).must_equal({})
      end
    end

    context "when the newline and remaining data arrive later" do
      let(:partial_line) { 'data: {"choices":[{"index":0,"delta":{"content":"He' }
      let(:remaining_lines) do
        %(y"}}]}\n) +
          %(data: {"choices":[{"index":0,"delta":{"content":" there"}}]}\n)
      end

      before do
        parser << partial_line
        parser << remaining_lines
      end

      it "preserves the full streamed content" do
        expect(stream.content).must_equal "Hey there"
      end

      it "preserves the full parsed message content" do
        expect(handler.body.dig("choices", 0, "message", "content")).must_equal "Hey there"
      end
    end

    context "when given reasoning content" do
      let(:first_chunk) { %(data: {"choices":[{"index":0,"delta":{"reasoning_content":"Think"}}]}\n) }
      let(:second_chunk) { %(data: {"choices":[{"index":0,"delta":{"content":"Answer"}}]}\n) }

      before do
        parser << first_chunk
        parser << second_chunk
      end

      it "emits assistant content through on_content" do
        expect(stream.content).must_equal "Answer"
      end

      it "emits reasoning content through on_reasoning_content" do
        expect(stream.reasoning_content).must_equal "Think"
      end

      it "preserves streamed reasoning content in the parsed body" do
        expect(handler.body.dig("choices", 0, "message", "reasoning_content")).must_equal "Think"
      end
    end

    context "when given a streamed tool call" do
      let(:system) do
        Class.new(LLM::Tool) do
          name "system"
          description "run shell commands"
        end
      end

      let(:chunk) do
        %(data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"system","arguments":"{\\"command\\":\\"date\\"}"}}]}}]}\n)
      end

      let(:call) { stream.calls.fetch(0) }
      let(:fn) { call.fetch(0) }

      before do
        LLM::Tool.clear_registry!
        system
        parser << chunk
      end

      it "emits a function through on_tool_call" do
        expect(fn).must_be_instance_of LLM::Function
      end

      it "does not emit an error for a resolved tool" do
        expect(call.fetch(1)).must_be_nil
      end

      it "preserves the function id" do
        expect(fn.id).must_equal "call_1"
      end

      it "preserves the function name" do
        expect(fn.name).must_equal "system"
      end

      it "preserves parsed arguments" do
        expect(fn.arguments).must_equal({"command" => "date"})
      end
    end

    context "when given an unresolved streamed tool call" do
      let(:chunk) do
        %(data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_2","type":"function","function":{"name":"missing","arguments":"{\\"command\\":\\"date\\"}"}}]}}]}\n)
      end

      let(:call) { stream.calls.fetch(0) }
      let(:fn) { call.fetch(0) }
      let(:error) { call.fetch(1) }

      before do
        LLM::Tool.clear_registry!
        parser << chunk
      end

      it "emits the unresolved function metadata" do
        expect(fn.id).must_equal "call_2"
        expect(fn.name).must_equal "missing"
        expect(fn.arguments).must_equal({"command" => "date"})
      end

      it "emits an in-band error" do
        expect(error.to_h).must_equal(
          id: "call_2", name: "missing",
          value: {error: true, type: "LLM::NoSuchToolError", message: "tool not found"}
        )
      end
    end

    context "when given a streamed Google tool call" do
      let(:handler_parser) { LLM::Google::StreamParser }
      let(:system) do
        Class.new(LLM::Tool) do
          name "system"
          description "run shell commands"
        end
      end

      let(:chunk) do
        %(data: {"candidates":[{"content":{"parts":[{"functionCall":{"name":"system","args":{"command":"date"}}}],"role":"model"},"index":0}]}\n)
      end

      let(:call) { stream.calls.fetch(0) }
      let(:fn) { call.fetch(0) }

      before do
        LLM::Tool.clear_registry!
        system
        parser << chunk
      end

      it "emits a resolved function through on_tool_call" do
        expect(fn).must_be_instance_of LLM::Function
        expect(fn.id).must_equal "google_call_0_0"
        expect(fn.name).must_equal "system"
        expect(fn.arguments).must_equal({"command" => "date"})
        expect(call.fetch(1)).must_be_nil
      end
    end

    context "when given a streamed Anthropic tool call" do
      let(:handler_parser) { LLM::Anthropic::StreamParser }
      let(:system) do
        Class.new(LLM::Tool) do
          name "system"
          description "run shell commands"
        end
      end

      let(:first_chunk) do
        %(event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_1","name":"system","input":{}}}\n\n)
      end
      let(:second_chunk) do
        %(event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"command\\": \\"date\\"}"}}\n\n)
      end
      let(:third_chunk) { %(event: content_block_stop\ndata: {"type":"content_block_stop","index":0}\n\n) }

      let(:call) { stream.calls.fetch(0) }
      let(:fn) { call.fetch(0) }

      before do
        LLM::Tool.clear_registry!
        system
        parser << first_chunk
        parser << second_chunk
        parser << third_chunk
      end

      it "emits a resolved function through on_tool_call" do
        expect(fn).must_be_instance_of LLM::Function
        expect(fn.id).must_equal "toolu_1"
        expect(fn.name).must_equal "system"
        expect(fn.arguments).must_equal({"command" => "date"})
        expect(call.fetch(1)).must_be_nil
      end
    end

    context "when given a streamed OpenAI Responses tool call" do
      let(:handler_parser) { LLM::OpenAI::Responses::StreamParser }
      let(:system) do
        Class.new(LLM::Tool) do
          name "system"
          description "run shell commands"
        end
      end

      let(:first_chunk) do
        %(event: response.output_item.added\ndata: {"type":"response.output_item.added","item":{"id":"fc_1","type":"function_call","status":"in_progress","arguments":"","call_id":"call_1","name":"system"},"output_index":0}\n\n)
      end
      let(:second_chunk) do
        %(event: response.function_call_arguments.delta\ndata: {"type":"response.function_call_arguments.delta","delta":"{\\"command\\":\\"date\\"}","item_id":"fc_1","output_index":0}\n\n)
      end
      let(:third_chunk) do
        %(event: response.function_call_arguments.done\ndata: {"type":"response.function_call_arguments.done","arguments":"{\\"command\\":\\"date\\"}","item_id":"fc_1","output_index":0}\n\n)
      end

      let(:call) { stream.calls.fetch(0) }
      let(:fn) { call.fetch(0) }

      before do
        LLM::Tool.clear_registry!
        system
        parser << first_chunk
        parser << second_chunk
        parser << third_chunk
      end

      it "emits a resolved function through on_tool_call" do
        expect(fn).must_be_instance_of LLM::Function
        expect(fn.id).must_equal "call_1"
        expect(fn.name).must_equal "system"
        expect(fn.arguments).must_equal({"command" => "date"})
        expect(call.fetch(1)).must_be_nil
      end
    end

    context "when given streamed OpenAI Responses reasoning content" do
      let(:handler_parser) { LLM::OpenAI::Responses::StreamParser }
      let(:first_chunk) do
        %(event: response.output_item.added\ndata: {"type":"response.output_item.added","item":{"id":"rs_1","type":"reasoning","summary":[]},"output_index":0}\n\n)
      end
      let(:second_chunk) do
        %(event: response.reasoning_summary_text.delta\ndata: {"type":"response.reasoning_summary_text.delta","output_index":0,"summary_index":0,"delta":"Think"}\n\n)
      end
      let(:third_chunk) do
        %(event: response.reasoning_summary_text.done\ndata: {"type":"response.reasoning_summary_text.done","output_index":0,"summary_index":0,"text":"Think"}\n\n)
      end
      let(:fourth_chunk) do
        %(event: response.output_item.added\ndata: {"type":"response.output_item.added","item":{"id":"msg_1","type":"message","content":[]},"output_index":1}\n\n)
      end
      let(:fifth_chunk) do
        %(event: response.content_part.added\ndata: {"type":"response.content_part.added","output_index":1,"content_index":0,"part":{"type":"output_text","text":""}}\n\n)
      end
      let(:sixth_chunk) do
        %(event: response.output_text.delta\ndata: {"type":"response.output_text.delta","output_index":1,"content_index":0,"delta":"Answer"}\n\n)
      end

      before do
        parser << first_chunk
        parser << second_chunk
        parser << third_chunk
        parser << fourth_chunk
        parser << fifth_chunk
        parser << sixth_chunk
      end

      it "emits assistant content through on_content" do
        expect(stream.content).must_equal "Answer"
      end

      it "emits reasoning content through on_reasoning_content" do
        expect(stream.reasoning_content).must_equal "Think"
      end

      it "preserves streamed reasoning content in the parsed body" do
        expect(handler.body.dig("output", 0, "summary", 0, "text")).must_equal "Think"
      end
    end
  end

  context "#on" do
    let(:events) { [] }
    let(:parser) do
      LLM::EventStream::Parser.new.tap do |instance|
        instance.on(:data) { events << _1 }
      end
    end

    before do
      parser << %(data: {"ok":true}\n)
    end

    let(:event) { events.fetch(0) }

    it "still yields event objects to callback subscribers" do
      expect(event).must_be_instance_of LLM::EventStream::Event
      expect(event.field).must_equal "data"
      expect(event.value).must_equal '{"ok":true}'
      expect(event.chunk).must_equal %(data: {"ok":true}\n)
    end
  end
end

Minitest.run(ARGV) || exit(1)
