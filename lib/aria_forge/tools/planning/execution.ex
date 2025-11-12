# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Planning.Execution do
  @moduledoc """
  Plan execution functionality.
  """

  alias AriaForge.Tools.{Objects, Materials, Scene, Introspection, Animation}
  alias AriaForge.Tools.Planning.Utils

  @doc """
  Executes plan steps sequentially.
  """
  @spec execute_plan_steps(map(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_plan_steps(plan, temp_dir) do
    steps = Map.get(plan, "steps", [])

    results =
      steps
      |> Enum.reduce_while({[], []}, fn step, {successes, failures} ->
        tool = Map.get(step, "tool")
        args = Map.get(step, "args", %{})

        result = execute_step(tool, args, temp_dir)

        case result do
          {:ok, _} ->
            {:cont, {[step | successes], failures}}

          {:error, reason} ->
            {:halt, {successes, [{step, reason} | failures]}}
        end
      end)

    case results do
      {success_steps, []} ->
        {:ok, "Plan executed successfully: #{length(success_steps)} steps completed"}

      {success_steps, failures} ->
        failure_count = length(failures)
        {:error, "Plan execution failed: #{failure_count} steps failed out of #{length(success_steps) + failure_count}"}
    end
  end

  @doc """
  Executes a single plan step and records its duration.
  """
  @spec execute_step(String.t(), map(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_step(tool, args, temp_dir) do
    # Record start time
    start_time = System.monotonic_time(:millisecond)
    
    result = case tool do
      "create_cube" ->
        name = Map.get(args, "name", "Cube")
        location = Map.get(args, "location", [0, 0, 0])
        size = Map.get(args, "size", 2.0)
        Objects.create_cube(name, location, size, temp_dir)

      "create_sphere" ->
        name = Map.get(args, "name", "Sphere")
        location = Map.get(args, "location", [0, 0, 0])
        radius = Map.get(args, "radius", 1.0)
        Objects.create_sphere(name, location, radius, temp_dir)

      "set_material" -> 
        object_name = Map.get(args, "object_name")
        material_name = Map.get(args, "material_name", "Material")
        color = Map.get(args, "color", [0.8, 0.8, 0.8, 1.0])
        Materials.set_material(object_name, material_name, color, temp_dir)

      "introspect_blender" ->
        object_path = Map.get(args, "object_path", "bmesh")
        Introspection.introspect_blender(object_path, temp_dir)

      "introspect_python" ->
        object_path = Map.get(args, "object_path", "json")
        prep_code = Map.get(args, "prep_code", nil)
        Introspection.introspect_python(object_path, prep_code, temp_dir)

      "reset_scene" ->
        Scene.reset_scene(temp_dir)

      "set_scene_fps" ->
        fps = Map.get(args, "fps", 30)
        Scene.set_scene_fps(fps, temp_dir)

      "get_scene_info" ->
        Scene.get_scene_info(temp_dir)

      "set_keyframe" ->
        object_name = Map.get(args, "object")
        property = Map.get(args, "property", "location")
        value = Map.get(args, "value")
        frame = Map.get(args, "frame", 1)
        Animation.set_keyframe(object_name, property, value, frame, temp_dir)

      _ ->
        {:error, "Unknown tool: #{tool}"}
    end
    
    # Record end time and calculate duration
    end_time = System.monotonic_time(:millisecond)
    duration_ms = end_time - start_time
    duration_seconds = duration_ms / 1000.0
    duration_iso = Utils.seconds_to_iso_duration(duration_seconds)
    
    # Return result with duration information
    case result do
      {:ok, message} ->
        {:ok, "#{message} (duration: #{duration_iso})"}
      error ->
        error
    end
  end
end

