# frozen_string_literal: true

module LLM::EventStream
  ##
  # @private
  class Parser
    COMPACT_THRESHOLD = 4096
    Visitor = Struct.new(:target, :on_data, :on_event, :on_id, :on_retry, :on_chunk)

    ##
    # @return [LLM::EventStream::Parser]
    def initialize
      @buffer = +""
      @events = Hash.new { |h, k| h[k] = [] }
      @cursor = 0
      @visitors = []
    end

    ##
    # Register a visitor
    # @param [#on_data] visitor
    # @return [void]
    def register(visitor)
      @visitors << Visitor.new(
        visitor,
        visitor.respond_to?(:on_data), visitor.respond_to?(:on_event),
        visitor.respond_to?(:on_id), visitor.respond_to?(:on_retry),
        visitor.respond_to?(:on_chunk)
      )
    end

    ##
    # Subscribe to an event
    # @param [Symbol] evtname
    # @param [Proc] block
    # @return [void]
    def on(evtname, &block)
      @events[evtname.to_s] << block
    end

    ##
    # Append an event to the internal buffer
    # @return [void]
    def <<(event)
      @buffer << event
      each_line { parse!(_1) }
    end

    ##
    # Returns the internal buffer
    # @return [String]
    def body
      return @buffer.dup if @cursor.zero?
      @buffer.byteslice(@cursor, @buffer.bytesize - @cursor) || +""
    end

    ##
    # Free the internal buffer
    # @return [void]
    def free
      @buffer.clear
      @cursor = 0
    end

    private

    def parse_event!(chunk, field, value)
      dispatch_visitors(field, value, chunk)
      dispatch_callbacks(field, value, chunk)
    end

    def parse!(chunk)
      field, value = Event.parse(chunk)
      parse_event!(chunk, field, value)
    end

    def dispatch_visitors(field, value, chunk)
      @visitors.each { dispatch_visitor(_1, field, value, chunk) }
    end

    def dispatch_callbacks(field, value, chunk)
      callbacks = @events[field]
      return if callbacks.empty?
      event = Event.new(chunk, field:, value:)
      callbacks.each { _1.call(event) }
    end

    def dispatch_visitor(visitor, field, value, chunk)
      target = visitor.target
      if field == "data"
        if visitor.on_data
          target.on_data(value, chunk)
        elsif visitor.on_chunk
          target.on_chunk(nil, chunk)
        end
      elsif field == "event"
        if visitor.on_event
          target.on_event(value, chunk)
        elsif visitor.on_chunk
          target.on_chunk(nil, chunk)
        end
      elsif field == "id"
        if visitor.on_id
          target.on_id(value, chunk)
        elsif visitor.on_chunk
          target.on_chunk(nil, chunk)
        end
      elsif field == "retry"
        if visitor.on_retry
          target.on_retry(value, chunk)
        elsif visitor.on_chunk
          target.on_chunk(nil, chunk)
        end
      elsif visitor.on_chunk
        target.on_chunk(nil, chunk)
      end
    end

    def each_line
      while (newline = @buffer.index("\n", @cursor))
        line = @buffer.byteslice(@cursor, newline - @cursor + 1)
        @cursor = newline + 1
        yield(line)
      end
      return if @cursor.zero?
      if @cursor >= @buffer.bytesize
        @buffer.clear
        @cursor = 0
      elsif @cursor >= COMPACT_THRESHOLD
        @buffer = @buffer.byteslice(@cursor, @buffer.bytesize - @cursor) || +""
        @cursor = 0
      end
    end
  end
end
