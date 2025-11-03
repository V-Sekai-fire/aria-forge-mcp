# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Utils do
  @moduledoc """
  Utility functions for bpy tools - Pythonx availability checking and scene setup.
  """

  require Logger

  @doc """
  Ensures Pythonx is available for operations.
  Returns :ok if available, :mock if not.
  """
  @spec ensure_pythonx() :: :ok | :mock
  def ensure_pythonx do
    # Python/bpy removed - always return mock
    :mock
  end

  @doc """
  Ensures the scene is set to 30 FPS for animations.
  Only executes when Pythonx/is available and not in test mode.
  """
  @spec ensure_scene_fps() :: :ok
  def ensure_scene_fps do
    # Python/bpy removed - no-op in mock mode
    :ok
  end

  defp check_pythonx_availability do
    # Python/bpy removed - always return mock
    :mock
  end
end

