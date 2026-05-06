# frozen_string_literal: true

module LLM
  class Agent
    attr_reader :llm

    def self.model(model = nil)
      return @model if model.nil?
      @model = model
    end

    def self.tools(*tools)
      return @tools || [] if tools.empty?
      @tools = tools.flatten
    end

    def self.skills(*skills)
      return @skills if skills.empty?
      @skills = skills.flatten
    end

    def self.schema(schema = nil)
      return @schema if schema.nil?
      @schema = schema
    end

    def self.instructions(instructions = nil)
      return @instructions if instructions.nil?
      @instructions = instructions
    end

    def self.concurrency(concurrency = nil)
      return @concurrency if concurrency.nil?
      @concurrency = concurrency
    end

    def self.tracer(tracer = nil, &block)
      return @tracer if tracer.nil? && !block
      @tracer = block || tracer
    end

    def initialize(llm, params = {})
      defaults = {
        model: self.class.model,
        tools: self.class.tools,
        skills: self.class.skills,
        schema: self.class.schema
      }.compact
      @concurrency = params.delete(:concurrency) || self.class.concurrency
      @llm = llm
      tracer = params.key?(:tracer) ? params.delete(:tracer) : self.class.tracer
      @tracer = resolve_option(tracer) unless tracer.nil?
      @ctx = LLM::Context.new(llm, defaults.merge(guard: true).merge(params))
    end

    def talk(prompt, params = {})
      run_loop(:talk, prompt, params)
    end
    alias_method :chat, :talk

    def respond(prompt, params = {})
      run_loop(:respond, prompt, params)
    end

    def messages
      @ctx.messages
    end

    def functions
      @tracer ? @llm.with_tracer(@tracer) { @ctx.functions } : @ctx.functions
    end

    def returns
      @ctx.returns
    end

    def call(...)
      @tracer ? @llm.with_tracer(@tracer) { @ctx.call(...) } : @ctx.call(...)
    end

    def wait(...)
      @tracer ? @llm.with_tracer(@tracer) { @ctx.wait(...) } : @ctx.wait(...)
    end

    def usage
      @ctx.usage
    end

    def interrupt!
      @ctx.interrupt!
    end
    alias_method :cancel!, :interrupt!

    def prompt(&b)
      @ctx.prompt(&b)
    end
    alias_method :build_prompt, :prompt

    def image_url(url)
      @ctx.image_url(url)
    end

    def local_file(path)
      @ctx.local_file(path)
    end

    def remote_file(res)
      @ctx.remote_file(res)
    end

    def tracer
      @tracer || @ctx.tracer
    end

    def model
      @ctx.model
    end

    def mode
      @ctx.mode
    end

    def concurrency
      @concurrency
    end

    def cost
      @ctx.cost
    end

    def context_window
      @ctx.context_window
    end

    def to_h
      @ctx.to_h
    end

    def to_json(...)
      to_h.to_json(...)
    end

    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} " \
      "@llm=#{@llm.class}, @mode=#{mode.inspect}, @messages=#{messages.inspect}>"
    end

    def serialize(**kw)
      @ctx.serialize(**kw)
    end
    alias_method :save, :serialize

    def deserialize(**kw)
      @ctx.deserialize(**kw)
    end
    alias_method :restore, :deserialize

    private

    def apply_instructions(new_prompt)
      instr = self.class.instructions
      return new_prompt unless instr
      if LLM::Prompt === new_prompt
        new_prompt.system(instr) if inject_instructions?(new_prompt)
        new_prompt
      else
        prompt do
          _1.system(instr) if inject_instructions?
          _1.user(new_prompt)
        end
      end
    end

    def inject_instructions?(prompt = nil)
      return false if @ctx.messages.any?(&:system?)
      return true if prompt.nil?
      !prompt.to_a.any?(&:system?)
    end

    def call_functions
      call(:functions)
    end

    def run_loop(method, prompt, params)
      loop = proc do
        max = params.key?(:tool_attempts) ? params.delete(:tool_attempts) : 25
        max = Integer(max) if max
        stream = params[:stream] || @ctx.params[:stream]
        stream.extra[:concurrency] = :call if LLM::Stream === stream
        res = @ctx.public_send(method, apply_instructions(prompt), params)
        loop do
          break if @ctx.functions.empty?
          if max
            max.times do
              break if @ctx.functions.empty?
              res = @ctx.public_send(method, call_functions, params)
            end
            break if @ctx.functions.empty?
            res = @ctx.public_send(method, @ctx.functions.map { rate_limit(_1) }, params)
          else
            res = @ctx.public_send(method, call_functions, params)
          end
        end
        res
      end
      @tracer ? @llm.with_tracer(@tracer, &loop) : loop.call
    end

    def rate_limit(function)
      LLM::Function::Return.new(function.id, function.name, {
        error: true,
        type: LLM::ToolLoopError.name,
        message: "tool loop rate limit reached"
      })
    end

    def resolve_option(option)
      Proc === option ? instance_exec(&option) : option
    end
  end
end
