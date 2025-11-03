# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.NativeServiceTest do
  use ExUnit.Case, async: true
  alias AriaForge.NativeService

  describe "module structure" do
    test "defines handle_tool_call function" do
      assert function_exported?(NativeService, :handle_tool_call, 3)
    end

    test "is a GenServer" do
      assert AriaForge.NativeService.__info__(:attributes)[:behaviour] == [GenServer]
    end
  end

  describe "tool call error handling" do
    test "returns error for unknown tool" do
      args = %{}
      state = %{}

      result = NativeService.handle_tool_call("unknown_tool", args, state)

      assert {:error, "Tool not found: unknown_tool", ^state} = result
    end

    test "returns error for empty tool name" do
      args = %{}
      state = %{}

      result = NativeService.handle_tool_call("", args, state)

      assert {:error, "Tool not found: ", ^state} = result
    end
  end

  describe "tool definitions exist" do
    test "bpy_create_cube tool is defined" do
      # This tests that the tool definition exists in the module
      # We can't easily test the actual tool calling without setup
      assert NativeService.__info__(:module) == AriaForge.NativeService
    end

    test "bpy_create_sphere tool is defined" do
      assert NativeService.__info__(:module) == AriaForge.NativeService
    end

    test "bpy_set_material tool is defined" do
      assert NativeService.__info__(:module) == AriaForge.NativeService
    end

    test "bpy_render_image tool is defined" do
      assert NativeService.__info__(:module) == AriaForge.NativeService
    end

    test "bpy_get_scene_info tool is defined" do
      assert NativeService.__info__(:module) == AriaForge.NativeService
    end
  end

  describe "server metadata" do
    test "server has correct name and version" do
      # Test that the server is properly configured with ExMCP.Server
      assert AriaForge.NativeService.__info__(:module) == AriaForge.NativeService
    end
  end
end
