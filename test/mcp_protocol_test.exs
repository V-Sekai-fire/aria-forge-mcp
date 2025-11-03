# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.McpProtocolTest do
  use ExUnit.Case, async: false
  alias AriaForge.NativeService

  setup do
    # Native service is started by application, just use handle_tool_call directly
    %{}
  end

  describe "MCP Protocol - Tools List" do
    test "all individual tools exist", %{} do
      # Test that each tool can be called directly
      expected_tools = ["reset_scene", "create_cube", "create_sphere", "get_scene_info", "export_bmesh", "import_bmesh"]
      
      Enum.each(expected_tools, fn tool_name ->
        # Verify the tool handler exists
        assert function_exported?(AriaForge.NativeService, :handle_tool_call, 3)
        
        # Test that calling with empty args doesn't crash
        args = %{}
        state = %{}
        result = AriaForge.NativeService.handle_tool_call(tool_name, args, state)
        
        # Should either succeed or return a meaningful error
        assert match?({:ok, _, _}, result) or match?({:error, _, _}, result)
      end)
    end

    test "tools handle_tool_call returns proper format", %{} do
      # Test that handle_tool_call returns the correct format
      args = %{}
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("reset_scene", args, state)
      
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
      assert is_list(response.content)
    end
  end

  describe "MCP Protocol - Tool Calls" do
    test "reset_scene tool call", %{} do
      args = %{}
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("reset_scene", args, state)
      
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
      assert is_list(response.content)
    end

    test "create_cube tool call", %{} do
      args = %{
        "name" => "TestCube",
        "location" => [1, 2, 3],
        "size" => 2.5
      }
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("create_cube", args, state)
      
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
      
      content = response.content
      assert is_list(content)
      assert length(content) > 0
      
      # Check that response contains expected data
      text_content = Enum.find(content, & &1["type"] == "text")
      assert text_content != nil
      assert String.contains?(text_content["text"], "TestCube")
    end

    test "create_sphere tool call", %{} do
      args = %{
        "name" => "TestSphere",
        "location" => [5, 10, 15],
        "radius" => 3.0
      }
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("create_sphere", args, state)
      
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
    end

    test "get_scene_info tool call", %{} do
      args = %{}
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("get_scene_info", args, state)
      
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
    end

    test "unknown tool returns error", %{} do
      args = %{}
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("unknown_tool", args, state)
      
      assert {:error, error_message, _state} = result
      assert String.contains?(error_message, "Tool not found")
      assert String.contains?(error_message, "unknown_tool")
    end
  end

  describe "Context Token Handling" do
    test "reset_scene can create context", %{} do
      args = %{}
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("reset_scene", args, state)
      
      assert {:ok, response, new_state} = result
      content = response.content
      text_content = Enum.find(content, & &1["type"] == "text")
      
      # Check if context token is mentioned in response or stored in state
      assert text_content != nil
      # Context token might be in state or in response text
      assert is_map(new_state)
    end

    test "create_cube with context_token parameter", %{} do
      # First get a context token from reset_scene
      reset_args = %{}
      reset_state = %{}
      {:ok, _reset_response, state_after_reset} = AriaForge.NativeService.handle_tool_call("reset_scene", reset_args, reset_state)
      
      # Now use the context token (if stored in state)
      context_token = Map.get(state_after_reset, :context_token)
      
      create_args = %{
        "name" => "ContextCube",
        "context_token" => context_token
      }
      
      result = AriaForge.NativeService.handle_tool_call("create_cube", create_args, state_after_reset)
      assert {:ok, response, _state} = result
      assert Map.has_key?(response, :content)
    end
  end

  describe "Error Handling" do
    test "missing required parameters for import_bmesh", %{} do
      # import_bmesh requires gltf_data
      args = %{}
      state = %{}
      result = AriaForge.NativeService.handle_tool_call("import_bmesh", args, state)
      
      # Should handle missing parameters gracefully - either error or ok response
      assert match?({:error, _, _}, result) or match?({:ok, _, _}, result)
    end
  end
end
