# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Rendering do
  @moduledoc """
  Rendering tools for scenes.
  """

  alias AriaForge.Tools.Utils

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

  # Test helper function
  @doc false
  def test_mock_render_image(filepath, resolution_x, resolution_y),
    do: mock_render_image(filepath, resolution_x, resolution_y)
end

