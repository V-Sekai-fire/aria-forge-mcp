# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Scene do
  @moduledoc """
  Scene management tools for (reset, get info, etc.)
  """

  alias AriaForge.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Resets the scene to a clean state by removing all objects.
  """
  @spec reset_scene(String.t()) :: result()
  def reset_scene(temp_dir) do
    mock_reset_scene()
  end

  defp mock_reset_scene do
    {:ok, "Reset scene - cleared all objects"}
  end

  @doc """
  Gets information about the current scene.
  """
  @spec get_scene_info(String.t()) :: result()
  def get_scene_info(temp_dir) do
    mock_get_scene_info()
  end

  defp mock_get_scene_info do
    {:ok,
     %{
       "scene_name" => "Scene",
       "frame_current" => 1,
       "frame_start" => 1,
       "frame_end" => 250,
       "fps" => 30,
       "fps_base" => 1,
       "objects" => ["Cube", "Light", "Camera"],
       "active_object" => "Cube"
     }}
  end

  @doc """
  Sets the scene frame rate (FPS).
  """
  @spec set_scene_fps(integer(), String.t()) :: result()
  def set_scene_fps(fps \\ 30, temp_dir) do
    mock_set_scene_fps(fps)
  end

  defp mock_set_scene_fps(fps) do
    {:ok, "Set scene FPS to #{fps}"}
  end

  # Test helper functions
  @doc false
  def test_mock_get_scene_info(), do: mock_get_scene_info()
  @doc false
  def test_mock_reset_scene(), do: mock_reset_scene()
  @doc false
  def test_mock_set_scene_fps(fps), do: mock_set_scene_fps(fps)
end
