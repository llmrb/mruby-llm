# frozen_string_literal: true

##
# The {LLM::A2A} class provides access to agents that implement the
# Agent2Agent (A2A) Protocol. A2A defines a standard way for
# independent AI agents to discover each other's capabilities,
# negotiate interaction modalities, and collaborate on tasks.
#
# In mruby-llm, {LLM::A2A} supports both HTTP+JSON/REST and JSON-RPC
# 2.0 protocol bindings and focuses on discovering agent skills that
# can be used through {LLM::Context} and {LLM::Agent}.
#
# @example REST binding (default)
#   a2a = LLM::A2A.rest(url: "https://agent.example.com")
#   card = a2a.card
#   puts card.skills.map(&:name)
#
# @example JSON-RPC binding
#   a2a = LLM::A2A.jsonrpc(url: "https://agent.example.com")
class LLM::A2A
  ##
  # @param [Symbol] binding
  #  The protocol binding to use. One of `:rest` or `:jsonrpc`.
  # @param [Object] transport
  #  The transport used to communicate with the remote A2A agent
  # @param [String] base_path
  #  Optional base path prefix for REST endpoints
  # @param [String] protocol_version
  #  The expected A2A protocol version. Defaults to "1.0".
  def initialize(transport:, binding: :rest, base_path: "", protocol_version: "1.0")
    @binding = binding
    @base_path = LLM::Utils.normalize_base_path(base_path)
    @protocol_version = protocol_version
    @transport = transport
    @id = 0
  end

  ##
  # Builds an A2A client over HTTP.
  # @param [String] url
  # @param [Hash<String, String>] headers
  # @param [Integer, nil] timeout
  # @param [LLM::Transport, Class, nil] transport
  # @param [Symbol] binding
  # @param [String] base_path
  # @param [String] protocol_version
  def self.http(url:, headers: {}, timeout: 30, transport: nil, binding: :rest, base_path: "", protocol_version: "1.0")
    new(
      binding:,
      base_path:,
      protocol_version:,
      transport: Transport::HTTP.new(
        url:, headers:, timeout:, transport:, protocol_version:
      )
    )
  end

  ##
  # Builds an A2A client over HTTP+JSON/REST.
  def self.rest(url:, headers: {}, timeout: 30, transport: nil, base_path: "", protocol_version: "1.0")
    http(
      url:,
      headers:,
      timeout:,
      transport:,
      binding: :rest,
      base_path:,
      protocol_version:
    )
  end

  ##
  # Builds an A2A client over HTTP+JSON with JSON-RPC 2.0.
  def self.jsonrpc(url:, headers: {}, timeout: 30, transport: nil, base_path: "", protocol_version: "1.0")
    http(
      url:,
      headers:,
      timeout:,
      transport:,
      binding: :jsonrpc,
      base_path:, protocol_version:
    )
  end

  ##
  # @return [Symbol]
  #  The active protocol binding
  def binding
    @binding
  end

  ##
  # Returns the remote agent card.
  # @return [LLM::A2A::Card]
  def card
    return @card if defined?(@card)
    @card = LLM::A2A::Card.new(transport.get("/.well-known/agent-card.json"))
  end
  alias_method :agent_card, :card

  ##
  # Returns the agent's skills adapted as callable tools.
  # @return [Array<Class<LLM::Tool>>]
  def skills
    @skills ||= card.skills.map { LLM::Tool.a2a(self, _1) }
  end
  alias_method :tools, :skills

  ##
  # Returns task-oriented A2A operations.
  # @return [LLM::A2A::Tasks]
  def tasks
    @tasks ||= LLM::A2A::Tasks.new(self)
  end

  ##
  # Returns push notification configuration operations.
  # @return [LLM::A2A::Notifications]
  def notifications
    @notifications ||= LLM::A2A::Notifications.new(self)
  end

  ##
  # Sends a message to the agent and returns the response.
  def send_message(text, configuration = {}, metadata: nil)
    body = build_request(
      "SendMessage",
      message: {role: "ROLE_USER", parts: [{text:}], messageId: next_id},
      configuration:,
      metadata:
    )
    execute_request(body)
  end

  ##
  # Sends a streaming message to the agent.
  def send_streaming_message(text, configuration = {}, &on_event)
    body = build_request(
      "SendStreamingMessage",
      message: {role: "ROLE_USER", parts: [{text:}], messageId: next_id},
      configuration:
    )
    execute_stream(body, &on_event)
  end

  ##
  # Gets the current state of a task.
  def get_task(task_id, history_length: nil)
    case @binding
    when :rest
      path = rest_path("/tasks/#{task_id}")
      path = "#{path}?historyLength=#{history_length}" if history_length
      res = transport.get(path)
    when :jsonrpc
      body = build_request("GetTask", id: task_id, historyLength: history_length)
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Cancels a task in progress.
  def cancel_task(task_id, metadata: nil)
    body = build_request("CancelTask", id: task_id, metadata:)
    case @binding
    when :rest
      res = transport.post(rest_path("/tasks/#{task_id}:cancel"), body)
    when :jsonrpc
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Subscribes to streaming updates for an existing task.
  def subscribe_to_task(task_id, &on_event)
    case @binding
    when :rest
      transport.get_stream(rest_path("/tasks/#{task_id}:subscribe")) { on_event&.call(LLM::Object.from(_1)) }
    when :jsonrpc
      body = build_request("SubscribeToTask", id: task_id)
      transport.post_stream("/", body) { on_event&.call(LLM::Object.from(_1)) }
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
  end

  ##
  # Lists tasks with optional filtering.
  def list_tasks(context_id: nil, status: nil, history_length: nil,
                 status_timestamp_after: nil, include_artifacts: nil,
                 page_size: 20, page_token: nil)
    case @binding
    when :rest
      params = {}
      params[:contextId] = context_id if context_id
      params[:status] = status if status
      params[:historyLength] = history_length if history_length
      params[:statusTimestampAfter] = status_timestamp_after if status_timestamp_after
      params[:includeArtifacts] = include_artifacts unless include_artifacts.nil?
      params[:pageSize] = page_size if page_size
      params[:pageToken] = page_token if page_token
      query = LLM::URI.encode_www_form(params)
      path = rest_path("/tasks")
      path = "#{path}?#{query}" unless query.empty?
      res = transport.get(path)
    when :jsonrpc
      body = build_request("ListTasks", contextId: context_id, status: status,
                                        historyLength: history_length,
                                        statusTimestampAfter: status_timestamp_after,
                                        includeArtifacts: include_artifacts,
                                        pageSize: page_size, pageToken: page_token)
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Creates a push notification configuration for a task.
  def create_task_push_notification_config(task_id, url:, token: nil, authentication: nil, id: nil)
    body = build_request("CreateTaskPushNotificationConfig",
      taskId: task_id, url:, token:, authentication:, id:)
    case @binding
    when :rest
      res = transport.post(rest_path("/tasks/#{task_id}/pushNotificationConfigs"), body)
    when :jsonrpc
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Retrieves a push notification configuration for a task.
  def get_task_push_notification_config(task_id, id)
    case @binding
    when :rest
      res = transport.get(rest_path("/tasks/#{task_id}/pushNotificationConfigs/#{id}"))
    when :jsonrpc
      body = build_request("GetTaskPushNotificationConfig", taskId: task_id, id:)
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Lists push notification configurations for a task.
  def list_task_push_notification_configs(task_id, page_size: nil, page_token: nil)
    case @binding
    when :rest
      params = {}
      params[:pageSize] = page_size if page_size
      params[:pageToken] = page_token if page_token
      query = LLM::URI.encode_www_form(params)
      path = rest_path("/tasks/#{task_id}/pushNotificationConfigs")
      path = "#{path}?#{query}" unless query.empty?
      res = transport.get(path)
    when :jsonrpc
      body = build_request("ListTaskPushNotificationConfigs",
        taskId: task_id, pageSize: page_size, pageToken: page_token)
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Deletes a push notification configuration for a task.
  def delete_task_push_notification_config(task_id, id)
    case @binding
    when :rest
      res = transport.delete(rest_path("/tasks/#{task_id}/pushNotificationConfigs/#{id}"))
    when :jsonrpc
      body = build_request("DeleteTaskPushNotificationConfig", taskId: task_id, id:)
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  ##
  # Returns the authenticated extended agent card.
  def extended_card
    case @binding
    when :rest
      res = transport.get(rest_path("/extendedAgentCard"))
    when :jsonrpc
      body = build_request("GetExtendedAgentCard")
      res = transport.post("/", body)
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::A2A::Card.new(res)
  end
  alias_method :get_extended_agent_card, :extended_card

  ##
  # @return [String]
  def inspect
    "#<#{self.class.name}:0x#{object_id.to_s(16)} @binding=#{@binding.inspect}>"
  end

  private

  attr_reader :transport

  def next_id
    @id += 1
  end

  def build_request(method, **params)
    case @binding
    when :rest
      params
    when :jsonrpc
      {jsonrpc: "2.0", method:, params: params.compact, id: next_id}
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
  end

  def execute_request(body)
    res = case @binding
    when :rest
      transport.post(rest_path("/message:send"), body)
    when :jsonrpc
      res = transport.post("/", body)
      if res["error"]
        raise LLM::A2A::Error.new(res["error"]["message"], res["error"]["code"])
      end
      res["result"] || res
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
    LLM::Object.from(res)
  end

  def execute_stream(body, &on_event)
    case @binding
    when :rest
      transport.post_stream(rest_path("/message:stream"), body) { on_event&.call(LLM::Object.from(_1)) }
    when :jsonrpc
      transport.post_stream("/", body) { on_event&.call(LLM::Object.from(_1)) }
    else
      raise LLM::A2A::Error, "Invalid A2A binding: #{@binding.inspect}"
    end
  end

  def rest_path(path)
    return path if @base_path.empty?
    "#{@base_path}#{path}"
  end
end
