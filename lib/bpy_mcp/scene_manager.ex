# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.SceneManager do
  @moduledoc """
  GenServer that manages a single Blender scene context.

  Provides process-based isolation and barriers for Blender operations.
  Each scene runs in its own process with automatic serialization of operations.
  """

  use GenServer
  require Logger

  @type scene_id :: String.t()
  @type operation_result :: {:ok, term()} | {:error, String.t()}

  # Client API

  @doc """
  Starts a new scene manager process for the given scene ID.
  """
  @spec start_link(scene_id()) :: GenServer.on_start()
  def start_link(scene_id) do
    GenServer.start_link(__MODULE__, scene_id, name: via_tuple(scene_id))
  end

  @doc """
  Creates a cube in the scene managed by this process.
  """
  @spec create_cube(pid(), String.t(), [number()], number()) :: operation_result()
  def create_cube(pid, name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0) do
    GenServer.call(pid, {:create_cube, name, location, size}, 30_000)
  end

  @doc """
  Creates a sphere in the scene managed by this process.
  """
  @spec create_sphere(pid(), String.t(), [number()], number()) :: operation_result()
  def create_sphere(pid, name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0) do
    GenServer.call(pid, {:create_sphere, name, location, radius}, 30_000)
  end

  @doc """
  Sets a material on an object in the scene.
  """
  @spec set_material(pid(), String.t(), String.t(), [number()]) :: operation_result()
  def set_material(pid, object_name, material_name \\ "Material", color \\ [0.8, 0.8, 0.8, 1.0]) do
    GenServer.call(pid, {:set_material, object_name, material_name, color}, 30_000)
  end

  @doc """
  Renders an image from the scene.
  """
  @spec render_image(pid(), String.t(), integer(), integer()) :: operation_result()
  def render_image(pid, filepath, resolution_x \\ 1920, resolution_y \\ 1080) do
    GenServer.call(pid, {:render_image, filepath, resolution_x, resolution_y}, 60_000)
  end

  @doc """
  Gets information about the scene.
  """
  @spec get_scene_info(pid()) :: operation_result()
  def get_scene_info(pid) do
    GenServer.call(pid, :get_scene_info, 10_000)
  end

  @doc """
  Gets the scene ID for this manager.
  """
  @spec get_scene_id(pid()) :: scene_id()
  def get_scene_id(pid) do
    GenServer.call(pid, :get_scene_id, 5_000)
  end

  # Server callbacks

  @impl true
  def init(scene_id) do
    Logger.info("Starting SceneManager for scene: #{scene_id}")

    # Create temp directory for this scene context
    temp_dir = BpyMcp.NativeService.Context.create_temp_dir()

    # Initialize scene state
    state = %{
      scene_id: scene_id,
      initialized: false,
      operation_count: 0,
      last_operation: nil,
      temp_dir: temp_dir
    }

    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    # Clean up temporary directory when process terminates
    temp_dir = Map.get(state, :temp_dir)
    if temp_dir && File.exists?(temp_dir) && String.starts_with?(temp_dir, System.tmp_dir!()) do
      try do
        File.rm_rf(temp_dir)
        Logger.debug("Cleaned up temp directory: #{temp_dir}")
      rescue
        e ->
          Logger.warning("Failed to clean up temp directory #{temp_dir}: #{Exception.message(e)}")
      end
    end
    :ok
  end

  @impl true
  def handle_call({:create_cube, name, location, size}, _from, state) do
    result = BpyMcp.BpyTools.create_cube(name, location, size)
    new_state = update_state(state, {:create_cube, [name, location, size]}, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:create_sphere, name, location, radius}, _from, state) do
    result = BpyMcp.BpyTools.create_sphere(name, location, radius)
    new_state = update_state(state, {:create_sphere, [name, location, radius]}, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:set_material, object_name, material_name, color}, _from, state) do
    result = BpyMcp.BpyTools.set_material(object_name, material_name, color)
    new_state = update_state(state, {:set_material, [object_name, material_name, color]}, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:render_image, filepath, resolution_x, resolution_y}, _from, state) do
    result = BpyMcp.BpyTools.render_image(filepath, resolution_x, resolution_y)
    new_state = update_state(state, {:render_image, [filepath, resolution_x, resolution_y]}, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:get_scene_info, _from, state) do
    # Use temp_dir from state or a default
    temp_dir = Map.get(state, :temp_dir, System.tmp_dir!())
    result = BpyMcp.BpyTools.get_scene_info(temp_dir)
    new_state = update_state(state, :get_scene_info, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:get_scene_id, _from, state) do
    {:reply, state.scene_id, state}
  end

  # Helper functions

  defp via_tuple(scene_id) do
    {:via, Registry, {BpyMcp.SceneRegistry, scene_id}}
  end

  defp update_state(state, operation, result) do
    %{
      state
      | operation_count: state.operation_count + 1,
        last_operation: {operation, result, DateTime.utc_now()}
    }
  end
end
