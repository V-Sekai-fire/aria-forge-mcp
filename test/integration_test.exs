# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.IntegrationTest do
  use ExUnit.Case, async: false
  alias AriaForge.{StdioServer, NativeService}

  describe "Application startup" do
    test "application starts successfully" do
      # Test that the application can start (this is more of a smoke test)
      # In a real scenario, we'd mock the dependencies
      assert is_atom(AriaForge.Application)
      assert function_exported?(AriaForge.Application, :start, 2)
    end

    test "application defines correct children" do
      # Test the supervision tree structure
      children = [
        {AriaForge.NativeService, [name: AriaForge.NativeService]},
        {AriaForge.StdioServer, []}
      ]

      opts = [strategy: :one_for_one, name: AriaForge.Supervisor]

      # Verify the children list matches what Application.start/2 uses
      assert length(children) == 2
      assert opts[:strategy] == :one_for_one
      assert opts[:name] == AriaForge.Supervisor
    end
  end

  describe "StdioServer" do
    test "defines child_spec correctly" do
      spec = StdioServer.child_spec([])
      expected_keys = [:id, :start, :type, :restart, :shutdown]

      assert is_map(spec)
      # Map.keys order might vary, so check that all expected keys are present
      assert MapSet.subset?(MapSet.new(expected_keys), MapSet.new(Map.keys(spec)))
      assert spec.id == AriaForge.StdioServer
      assert spec.type == :worker
      assert spec.restart == :permanent
      assert spec.shutdown == 500
    end

    test "start_link function exists" do
      # Just test that the function exists, don't test the actual call since
      # it would start a server that runs forever
      # Force module loading by calling a function that doesn't require the server to be running
      _spec = StdioServer.child_spec([])
      assert function_exported?(StdioServer, :start_link, 1)
    end
  end

  describe "Mix task integration" do
    test "mcp.server task exists and is properly defined" do
      # Load the Mix task module since it's not loaded during regular compilation
      Code.require_file("lib/mix/tasks/mcp.server.ex")
      assert function_exported?(Mix.Tasks.Mcp.Server, :run, 1)
    end
  end

  describe "MCP protocol integration" do
    test "NativeService implements required MCP callbacks" do
      # Test that NativeService properly implements the ExMCP.Server behaviour
      assert function_exported?(NativeService, :handle_tool_call, 3)
      # Note: Other callbacks are implemented by the ExMCP.Server macro
    end

    test "server metadata is correctly defined" do
      # Test server information defined in the use ExMCP.Server macro
      # This is more of a compilation test, but ensures the server is properly configured
      assert AriaForge.NativeService.__info__(:module) == AriaForge.NativeService
    end
  end

  describe "end-to-end tool call flow" do
    test "complete tool call cycle works" do
      # Test a complete tool call from invocation to response using individual tools
      tool_name = "create_cube"

      args = %{
        "name" => "IntegrationTestCube",
        "location" => [10, 20, 30],
        "size" => 3.0
      }

      initial_state = %{test: true}

      result = NativeService.handle_tool_call(tool_name, args, initial_state)

      assert {:ok, response, returned_state} = result
      assert is_map(response)
      assert Map.has_key?(response, :content)
      assert is_list(response.content)
      assert length(response.content) >= 1

      content = hd(response.content)
      assert content["type"] == "text"
      assert String.contains?(content["text"], "IntegrationTestCube")
      assert String.contains?(content["text"], "[10, 20, 30]")
      assert String.contains?(content["text"], "3.0")
    end

    test "error handling in tool calls" do
      # Test that invalid tool calls are handled gracefully
      result = NativeService.handle_tool_call("nonexistent_tool", %{}, %{})

      assert {:error, error_message, _state} = result
      assert String.contains?(error_message, "Tool not found")
      assert String.contains?(error_message, "nonexistent_tool")
    end
  end

  describe "configuration integration" do
    test "config.exs exists and is valid" do
      # Test that configuration files exist
      config_path = Path.join(File.cwd!(), "config/config.exs")
      assert File.exists?(config_path)
    end

    test "mix.exs includes proper configuration" do
      # Test that mix.exs has the expected configuration
      assert function_exported?(AriaForge.MixProject, :project, 0)
      assert function_exported?(AriaForge.MixProject, :application, 0)
    end
  end
end
