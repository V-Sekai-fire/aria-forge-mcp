# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.MCPBlenderHelper do
  @moduledoc """
  Helper module for calling MCP Blender tools.
  
  This module provides a wrapper for calling mcp_blender_execute_blender_code
  which is available at runtime through the MCP protocol.
  """

  # Suppress compile-time warnings - this function is available at runtime via MCP
  @compile {:no_warn_undefined, [mcp_blender_execute_blender_code: 1]}

  @doc """
  Executes Blender Python code via MCP Blender tool.
  
  This function calls the mcp_blender_execute_blender_code tool which should
  be available at runtime through the MCP protocol.
  """
  @spec execute_blender_code(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_blender_code(code) when is_binary(code) do
    # Call the MCP tool function directly - same pattern as Objects and Rendering modules
    # This function is available at runtime through the MCP client
    mcp_blender_execute_blender_code(code: code)
  rescue
    e ->
      {:error, "MCP Blender not available: #{Exception.message(e)}"}
  end
end

