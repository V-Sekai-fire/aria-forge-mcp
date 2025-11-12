# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Animation do
  @moduledoc """
  Animation tools for setting keyframes and managing animations.
  """

  alias AriaForge.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Sets a keyframe for an object property at a specific frame.
  """
  @spec set_keyframe(String.t(), String.t(), [number()] | number(), integer(), String.t()) :: result()
  def set_keyframe(object_name, property \\ "location", value, frame \\ 1, temp_dir) do
    mock_set_keyframe(object_name, property, value, frame)
  end

  defp mock_set_keyframe(object_name, property, value, frame) do
    {:ok, "Set keyframe for #{object_name}.#{property} = #{inspect(value)} at frame #{frame}"}
  end

  # Test helper functions
  @doc false
  def test_mock_set_keyframe(object_name, property, value, frame),
    do: mock_set_keyframe(object_name, property, value, frame)
end

