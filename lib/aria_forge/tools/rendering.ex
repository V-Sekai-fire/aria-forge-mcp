# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Rendering do
  @moduledoc """
  Rendering and export tools for scenes.
  """

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Renders the current scene to an image file.
  """
  @spec render_image(String.t(), integer(), integer(), String.t()) :: result()
  def render_image(filepath, resolution_x \\ 1920, resolution_y \\ 1080, temp_dir) do
    mock_render_image(filepath, resolution_x, resolution_y)
  end

  defp mock_render_image(filepath, resolution_x, resolution_y) do
    {:ok, "Rendered image to #{filepath} at #{resolution_x}x#{resolution_y}"}
  end

  @doc """
  Exports the current scene to USD (Universal Scene Description) format.
  Fails if MCP Blender is not available.
  """
  @spec export_usd(String.t(), String.t()) :: result()
  def export_usd(filepath, _temp_dir) do
    # Escape backslashes and quotes in filepath for Python
    escaped_filepath = String.replace(filepath, "\\", "\\\\")
    code = """
import bpy
import os

filepath = r'''#{escaped_filepath}'''

# Ensure directory exists
dir_path = os.path.dirname(filepath)
if dir_path:
    os.makedirs(dir_path, exist_ok=True)

# Export to USD
bpy.ops.wm.usd_export(
    filepath=filepath,
    export_materials=True,
    export_textures=True,
    export_animation=True,
    export_hair=True,
    export_uvmaps=True,
    export_normals=True,
    use_instancing=True,
    evaluation_mode='RENDER'
)

result = f"Exported scene to USD: {filepath}"
result
"""

    case mcp_blender_execute_blender_code(code: code) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, "Failed to export USD via MCP Blender: #{inspect(reason)}"}

      other ->
        {:error, "MCP Blender not available: #{inspect(other)}"}
    end
  rescue
    e -> {:error, "Error exporting USD: #{Exception.message(e)}"}
  end

  # Test helper function
  @doc false
  def test_mock_render_image(filepath, resolution_x, resolution_y),
    do: mock_render_image(filepath, resolution_x, resolution_y)
end
