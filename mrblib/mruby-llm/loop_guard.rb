# frozen_string_literal: true

##
# {LLM::LoopGuard LLM::LoopGuard} is the built-in implementation of
# llm.rb's `guard` capability.
#
# A guard is a context-level supervisor for agentic execution. It can inspect
# the current runtime state and return a warning string when pending tool work
# should be blocked before the loop keeps going.
#
# {LLM::LoopGuard LLM::LoopGuard} detects when a context is repeating the same
# tool-call pattern instead of making progress. It is directly inspired by
# General Intelligence Systems and its doom-loop detection approach.
#
# The public interface is intentionally small:
# - `call(ctx)` returns `nil` when no intervention is needed
# - `call(ctx)` returns a warning string when pending tool execution should be blocked
#
# {LLM::Context LLM::Context} can use that warning to return in-band
# {LLM::GuardError LLM::GuardError} tool errors, and
# {LLM::Agent LLM::Agent} enables this guard by default through its wrapped
# context.
#
class LLM::LoopGuard
  ##
  # The default number of repeated tool-call patterns required before
  # the guard intervenes.
  # @return [Integer]
  DEFAULT_THRESHOLD = 3

  ##
  # Returns the repetition threshold.
  # @return [Integer]
  attr_reader :threshold

  ##
  # @param [Hash] config
  # @option config [Integer] :threshold
  #  How many repeated tool-call patterns must appear at the tail of the
  #  sequence before the guard returns a warning.
  def initialize(config = {})
    @threshold = config.fetch(:threshold, DEFAULT_THRESHOLD)
  end

  ##
  # Checks the current context for repeated tool-call patterns.
  #
  # This method inspects assistant tool calls only. It reduces each call to a
  # `[tool_name, arguments]` signature and checks whether the tail of the
  # sequence is repeating.
  #
  # @param [LLM::Context] ctx
  # @return [String, nil]
  #  Returns a warning string when pending tool execution should be blocked,
  #  or `nil` when execution should continue.
  def call(ctx)
    repetitions = detect(ctx.messages.to_a)
    repetitions ? warning(repetitions) : nil
  end

  private

  def detect(messages)
    signatures = extract_signatures(messages)
    return if signatures.size < threshold
    check_repeating_pattern(signatures)
  end

  def warning(repetitions)
    <<~MSG
      SYSTEM NOTICE: Repeated tool-call pattern detected - the same pattern has repeated #{repetitions} times.
      You are stuck in a loop and not making progress. Stop and try a fundamentally different approach:
      - Re-read the relevant context before retrying
      - Try a different tool or strategy
      - Break the problem into smaller steps
      - If a tool keeps failing, investigate why before retrying
    MSG
  end

  def extract_signatures(messages)
    messages
      .select { _1.respond_to?(:functions) && _1.assistant? }
      .flat_map { |message| message.functions.map { [_1.name.to_s, _1.arguments.to_s] } }
  end

  def check_repeating_pattern(sequence)
    max_pattern_len = sequence.size / threshold
    (1..max_pattern_len).each do |pattern_len|
      count = count_tail_repetitions(sequence, pattern_len)
      return count if count >= threshold
    end
    nil
  end

  def count_tail_repetitions(sequence, length)
    return 0 if sequence.size < length
    pattern = sequence.last(length)
    count = 1
    pos = sequence.size - length
    while pos >= length
      candidate = sequence[(pos - length)...pos]
      break unless candidate == pattern
      count += 1
      pos -= length
    end
    count
  end
end
