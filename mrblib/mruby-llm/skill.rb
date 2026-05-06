# frozen_string_literal: true

module LLM
  ##
  # {LLM::Skill LLM::Skill} represents a directory-backed packaged capability.
  # A skill directory must contain a `SKILL.md` file with YAML frontmatter.
  # Skills can expose themselves as normal {LLM::Tool LLM::Tool} classes through
  # {#to_tool}. This keeps skills on the same execution path as local tools.
  class Skill
    ##
    # Load a skill from a directory.
    # @param [String, Pathname] path
    # @return [LLM::Skill]
    def self.load(path)
      new(path).tap(&:load!)
    end

    ##
    # Returns the skill directory.
    # @return [String]
    attr_reader :path

    ##
    # Returns the skill name.
    # @return [String]
    attr_reader :name

    ##
    # Returns the skill description.
    # @return [String]
    attr_reader :description

    ##
    # Returns the skill instructions.
    # @return [String]
    attr_reader :instructions

    ##
    # Returns the skill frontmatter.
    # @return [LLM::Object]
    attr_reader :frontmatter

    ##
    # Returns the skill tools.
    # @return [Array<Class<LLM::Tool>>]
    attr_reader :tools

    ##
    # @param [String] path
    #  The path to a directory
    # @return [LLM::Skill]
    def initialize(path)
      @path = path.to_s
      @name = ::File.basename(@path)
      @description = "Skill: #{@name}"
      @instructions = ""
      @frontmatter = LLM::Object.from({})
      @tools = []
    end

    ##
    # Load and parse the skill.
    # @return [LLM::Skill]
    def load!
      path = ::File.join(@path, "SKILL.md")
      parse(::File.read(path))
      self
    end

    ##
    # Execute the skill by wrapping it in a small agent with the skill
    # instructions. The context is bound explicitly by the caller so the
    # nested agent can inherit context-level behavior such as streaming.
    # @param [LLM::Context] ctx
    # @return [Hash]
    def call(ctx)
      instructions, tools, tracer = self.instructions, self.tools, ctx.llm.tracer
      params = ctx.params.merge(mode: ctx.mode).reject { [:tools, :schema].include?(_1) }
      concurrency = params[:stream].extra[:concurrency] if LLM::Stream === params[:stream]
      params[:concurrency] = concurrency if concurrency
      agent = Class.new(LLM::Agent) do
        instructions(instructions)
        tools(*tools)
        tracer(tracer)
      end.new(ctx.llm, params)
      agent.messages.concat(messages_for(ctx))
      res = agent.talk("Solve the user's query.")
      {content: res.content}
    end

    ##
    # Expose the skill as a normal LLM::Tool. The context is bound explicitly
    # when the tool class is built.
    # @param [LLM::Context] ctx
    # @return [Class<LLM::Tool>]
    def to_tool(ctx)
      skill = self
      Class.new(LLM::Tool) do
        name skill.name
        description skill.description
        attr_accessor :tracer

        define_singleton_method(:skill?) do
          true
        end

        define_method(:call) do
          skill.call(ctx)
        end
      end
    end

    private

    def messages_for(ctx)
      messages = ctx.messages
        .to_a
        .select { _1.user? || _1.assistant? }
        .reject { _1.tool_call? || _1.tool_return? }
        .last(8)
      return messages if messages.empty?
      [LLM::Message.new(:user, "Recent context:"), *messages]
    end

    def parse(content)
      match = content.match(/\A---\s*\n(.*?)\n---\s*\n?(.*)\z/m)
      unless match
        @instructions = content
        return
      end
      @frontmatter = LLM::Object.from(LLM::YAML.safe_load(match[1]) || {})
      @name = @frontmatter.name || @name
      @description = @frontmatter.description || @description
      @tools = [*@frontmatter.tools].map { LLM::Tool.find_by_name!(_1) }
      @instructions = match[2]
    end
  end
end
