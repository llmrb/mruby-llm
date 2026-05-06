# frozen_string_literal: true

##
# The {LLM::Tool LLM::Tool} class represents a local tool
# that can be called by an LLM. Under the hood, it is a wrapper
# around {LLM::Function LLM::Function} but allows the definition
# of a function (also known as a tool) as a class.
# @example
#   class System < LLM::Tool
#     name "system"
#     description "Runs system commands"
#     params do |schema|
#       schema.object(command: schema.string.required)
#     end
#
#     def call(command:)
#       {success: Kernel.system(command)}
#     end
#   end
class LLM::Tool
  require_relative "tool/param"
  extend LLM::Tool::Param
  extend LLM::Function::Registry

  types = [
    :Leaf, :String, :Enum,
    :AllOf, :AnyOf, :OneOf,
    :Object, :Integer, :Number,
    :Array, :Boolean, :Null
  ]
  types.each do |constant|
    const_set constant, LLM::Schema.const_get(constant)
  end

  ##
  # @param [LLM::MCP] mcp
  #  The MCP client that will execute the tool call
  # @param [Hash] tool
  #  A tool (as a raw Hash)
  # @return [Class<LLM::Tool>]
  #  Returns a subclass of LLM::Tool
  def self.mcp(mcp, tool)
    lock do
      @mcp = true
      klass = Class.new(LLM::Tool) do
        name tool["name"]
        description tool["description"]
        params { tool["inputSchema"] || {type: "object", properties: {}} }

        define_singleton_method(:inspect) do
          "<LLM::Tool:0x#{object_id.to_s(16)} name=#{tool["name"]} (mcp)>"
        end
        singleton_class.alias_method :to_s, :inspect

        define_singleton_method(:mcp?) do
          true
        end

        define_method(:call) do |**args|
          mcp.call_tool(tool["name"], args)
        end
      end
      @mcp = false
      register(klass)
      klass
    ensure
      @mcp = false
    end
  end

  ##
  # Clear the registry
  # @return [void]
  def self.clear_registry!
    lock do
      @__registry.each_value { LLM::Function.unregister(_1.function) }
      super
    end
  end

  ##
  # Registers a tool and its function.
  # @param [LLM::Tool] tool
  # @api private
  def self.register(tool)
    super
    LLM::Function.register(tool.function)
  end

  ##
  # Unregister a tool from the registry
  # @param [LLM::Tool] tool
  # @api private
  def self.unregister(tool)
    lock do
      LLM::Function.unregister(tool.function)
      super
      tool
    end
  end

  ##
  # Registers the tool as a function when inherited
  # @param [Class] klass The subclass
  # @return [void]
  def self.inherited(tool)
    LLM.lock(:inherited) do
      tool.instance_eval { @__monitor ||= Monitor.new }
      tool.function.register(tool)
      LLM::Tool.register(tool) unless lock { @mcp }
    end
  end

  ##
  # Returns (or sets) the tool name
  # @param [String, nil] name The tool name
  # @return [String]
  def self.name(name = nil)
    lock do
      name ? function.name(name) : function.name
    end
  end

  ##
  # Returns all registered tool classes with definitions.
  # @return [Array<Class<LLM::Tool>>]
  def self.registry
    super.select(&:name)
  end

  ##
  # Finds a registered tool by name.
  # @param [String] name
  # @return [Class<LLM::Tool>]
  # @raise [LLM::NoSuchToolError]
  def self.find_by_name!(name)
    find_by_name(name) || raise(LLM::NoSuchToolError, "no such tool #{name.inspect}")
  end

  ##
  # Returns (or sets) the tool description
  # @param [String, nil] desc The tool description
  # @return [String]
  def self.description(desc = nil)
    lock do
      desc ? function.description(desc) : function.description
    end
  end

  ##
  # Returns (or sets) tool parameters
  # @yieldparam [LLM::Schema] schema The schema object to define parameters
  # @return [LLM::Schema]
  def self.params(&)
    lock do
      function.tap { _1.params(&) }
    end
  end

  ##
  # @api private
  def self.function
    lock do
      @function ||= LLM::Function.new(nil)
    end
  end

  ##
  # Returns true if the tool is an MCP tool
  # @return [Boolean]
  def self.mcp?
    false
  end

  ##
  # Returns a function bound to this tool instance.
  # @return [LLM::Function]
  def function
    @function ||= self.class.function.dup.tap { _1.register(self) }
  end

  ##
  # Returns true if the tool is an MCP tool
  # @return [Boolean]
  def mcp?
    self.class.mcp?
  end

  ##
  # Called when an in-flight tool run is interrupted.
  # Tools can override this to implement cooperative cleanup.
  # @return [nil]
  def on_interrupt
  end

  ##
  # Called when an in-flight tool run is cancelled.
  # @return [nil]
  def on_cancel
    on_interrupt
  end
end
