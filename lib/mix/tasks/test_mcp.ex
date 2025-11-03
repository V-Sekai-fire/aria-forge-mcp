defmodule Mix.Tasks.TestMcp do
  @moduledoc """
  Test the MCP server from CLI by calling NativeService directly.
  """
  use Mix.Task

  @shortdoc "Test MCP server functionality from CLI"
  def run(_args) do
    Mix.Task.run("app.start")
    
    alias AriaForge.NativeService
    
    IO.puts("🧪 Testing aria-forget MCP Server via CLI")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Initialize the server state
    state = %{}
    
    # Test 1: List tools
    IO.puts("\n📋 Test 1: List tools")
    request = %{"method" => "tools/list", "params" => %{}}
    case NativeService.handle_request(request, %{}, state) do
      {:reply, response, new_state} ->
        tools = get_in(response, ["result", "tools"]) || []
        IO.puts("✅ Found #{length(tools)} tools:")
        Enum.each(tools, fn tool ->
          IO.puts("   - #{tool["name"]}: #{tool["description"]}")
        end)
        _state = new_state
      other ->
        IO.puts("❌ Error: #{inspect(other)}")
    end
    
    # Test 2: List resources
    IO.puts("\n📦 Test 2: List resources")
    request = %{"method" => "resources/list", "params" => %{}}
    case NativeService.handle_request(request, %{}, state) do
      {:reply, response, _new_state} ->
        resources = get_in(response, ["result", "resources"]) || []
        IO.puts("✅ Found #{length(resources)} resources:")
        Enum.each(resources, fn resource ->
          IO.puts("   - #{resource["uri"]} (#{resource["name"]})")
        end)
      other ->
        IO.puts("❌ Error: #{inspect(other)}")
    end
    
    # Test 3: Get context token for default scene
    IO.puts("\n🔑 Test 3: Acquire default context")
    case NativeService.handle_tool_call("acquire_context", %{"scene_id" => "default"}, state) do
      {:ok, %{content: content}, new_state} ->
        text = Enum.at(content, 0)["text"] || inspect(content)
        IO.puts("✅ Result: #{text}")
        _state = new_state
      {:error, reason, _new_state} ->
        IO.puts("❌ Error: #{reason}")
      other ->
        IO.puts("❌ Unexpected result: #{inspect(other)}")
    end
    
    # Test 4: Execute a command
    IO.puts("\n🎨 Test 4: Create a cube")
    case NativeService.handle_tool_call("create_cube", %{
      "name" => "TestCube",
      "location" => [1, 2, 3],
      "size" => 2.5
    }, state) do
      {:ok, %{content: content}, new_state} ->
        text = Enum.at(content, 0)["text"] || inspect(content)
        IO.puts("✅ Result: #{text}")
        _state = new_state
      {:error, reason, _new_state} ->
        IO.puts("❌ Error: #{reason}")
      other ->
        IO.puts("❌ Unexpected result: #{inspect(other)}")
    end
    
    # Test 5: List contexts
    IO.puts("\n📝 Test 5: List active contexts")
    case NativeService.handle_tool_call("list_contexts", %{}, state) do
      {:ok, %{content: content}, _new_state} ->
        text = Enum.at(content, 0)["text"] || inspect(content)
        IO.puts("✅ Result: #{text}")
      {:error, reason, _new_state} ->
        IO.puts("❌ Error: #{reason}")
      other ->
        IO.puts("❌ Unexpected result: #{inspect(other)}")
    end
    
    IO.puts("\n" <> String.duplicate("=", 52))
    IO.puts("✅ All tests completed!")
  end
end

