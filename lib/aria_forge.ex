# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge do
  @moduledoc """
  MCP - Model Context Protocol server for 3D operations.

  Provides context-managed access to functionality through process barriers.
  """

  @type context_result :: {:ok, pid()} | {:error, String.t()}
  @type context_info :: %{scene_id: String.t(), pid: pid(), operation_count: integer()}

  @doc """
  Sets the current scene context.

  Creates or retrieves a scene manager process for the given scene ID.
  Returns the process PID which serves as the context handle.

  ## Parameters
    - scene_id: Unique identifier for the scene context

  ## Returns
    - `{:ok, pid}` - Context handle (process PID) for the scene
    - `{:error, reason}` - Error message if context creation fails
  """
  @spec set_context(String.t()) :: context_result()
  def set_context(scene_id) when is_binary(scene_id) and scene_id != "" do
    case Registry.lookup(AriaForge.SceneRegistry, scene_id) do
      [{pid, _}] ->
        # Scene already exists
        {:ok, pid}

      [] ->
        # Create new scene manager
        case DynamicSupervisor.start_child(AriaForge.SceneSupervisor, {AriaForge.SceneManager, scene_id}) do
          {:ok, pid} ->
            {:ok, pid}

          {:error, reason} ->
            {:error, "Failed to create scene context: #{inspect(reason)}"}
        end
    end
  end

  def set_context(_), do: {:error, "Invalid scene ID"}

  @doc """
  Gets information about the current context (if any).

  ## Returns
    - `{:ok, context_info}` - Information about the current context
    - `{:error, reason}` - No current context or error
  """
  @spec get_context() :: {:ok, context_info()} | {:error, String.t()}
  def get_context do
    # For now, return info about all contexts since there's no "current" context concept
    # This could be enhanced to track a default context per process
    case list_contexts() do
      {:ok, []} ->
        {:error, "No active contexts"}

      {:ok, contexts} ->
        # Return the first context as "current" for now
        {:ok, List.first(contexts)}

      error ->
        error
    end
  end

  @doc """
  Lists all active scene contexts.

  ## Returns
    - `{:ok, [context_info]}` - List of active scene contexts
    - `{:error, reason}` - Error retrieving context list
  """
  @spec list_contexts() :: {:ok, [context_info()]} | {:error, String.t()}
  def list_contexts do
    try do
      # Use Registry.select to get all entries
      # Pattern: {{key, pid, value}, guards, select}
      contexts =
        Registry.select(AriaForge.SceneRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
        |> Enum.map(fn {scene_id, pid, _value} ->
          operation_count = get_operation_count(pid)
          %{scene_id: scene_id, pid: pid, operation_count: operation_count}
        end)

      {:ok, contexts}
    rescue
      e ->
        {:error, "Failed to list contexts: #{Exception.message(e)}"}
    end
  end

  @doc """
  Creates a cube in the specified scene context.

  ## Parameters
    - context_pid: Scene context handle (PID from set_context/1)
    - name: Name for the cube object
    - location: [x, y, z] coordinates
    - size: Size of the cube

  ## Returns
    - `{:ok, result}` - Success message
    - `{:error, reason}` - Error message
  """
  @spec create_cube(pid(), String.t(), [number()], number()) :: AriaForge.SceneManager.operation_result()
  def create_cube(context_pid, name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0) do
    AriaForge.SceneManager.create_cube(context_pid, name, location, size)
  end

  @doc """
  Creates a sphere in the specified scene context.

  ## Parameters
    - context_pid: Scene context handle (PID from set_context/1)
    - name: Name for the sphere object
    - location: [x, y, z] coordinates
    - radius: Radius of the sphere

  ## Returns
    - `{:ok, result}` - Success message
    - `{:error, reason}` - Error message
  """
  @spec create_sphere(pid(), String.t(), [number()], number()) :: AriaForge.SceneManager.operation_result()
  def create_sphere(context_pid, name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0) do
    AriaForge.SceneManager.create_sphere(context_pid, name, location, radius)
  end

  @doc """
  Sets a material on an object in the specified scene context.

  ## Parameters
    - context_pid: Scene context handle
    - object_name: Name of the object to modify
    - material_name: Name of the material
    - color: [r, g, b, a] color values

  ## Returns
    - `{:ok, result}` - Success message
    - `{:error, reason}` - Error message
  """
  @spec set_material(pid(), String.t(), String.t(), [number()]) :: AriaForge.SceneManager.operation_result()
  def set_material(context_pid, object_name, material_name \\ "Material", color \\ [0.8, 0.8, 0.8, 1.0]) do
    AriaForge.SceneManager.set_material(context_pid, object_name, material_name, color)
  end

  @doc """
  Renders an image from the specified scene context.

  ## Parameters
    - context_pid: Scene context handle
    - filepath: Output file path
    - resolution_x: Render width
    - resolution_y: Render height

  ## Returns
    - `{:ok, result}` - Success message
    - `{:error, reason}` - Error message
  """
  @spec render_image(pid(), String.t(), integer(), integer()) :: AriaForge.SceneManager.operation_result()
  def render_image(context_pid, filepath, resolution_x \\ 1920, resolution_y \\ 1080) do
    AriaForge.SceneManager.render_image(context_pid, filepath, resolution_x, resolution_y)
  end

  @doc """
  Gets scene information from the specified context.

  ## Parameters
    - context_pid: Scene context handle

  ## Returns
    - `{:ok, scene_info}` - Scene information map
    - `{:error, reason}` - Error message
  """
  @spec get_scene_info(pid()) :: AriaForge.SceneManager.operation_result()
  def get_scene_info(context_pid) do
    AriaForge.SceneManager.get_scene_info(context_pid)
  end

  # Helper functions

  @doc """
  Hello world - basic function for testing.
  """
  def hello do
    :world
  end

  # Private helper to get operation count from scene manager
  defp get_operation_count(_pid) do
    try do
      # This is a simplified version - in a real implementation,
      # we'd query the GenServer state directly
      0
    rescue
      _ -> 0
    end
  end
end
