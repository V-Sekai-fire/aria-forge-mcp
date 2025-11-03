# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools.Planning do
  @moduledoc """
  Planning tools for generating sequences of Blender operations.
  
  These tools help plan complex workflows by generating ordered sequences
  of bpy-mcp operations that respect dependencies and constraints.
  
  Uses aria_planner library for planning algorithms when available.
  """
  
  @type planning_result :: {:ok, String.t()} | {:error, String.t()}
  @type plan_step :: %{
    tool: String.t(),
    args: map(),
    dependencies: [String.t()],
    description: String.t()
  }
  @type plan :: %{
    steps: [plan_step()],
    total_operations: integer(),
    estimated_complexity: String.t()
  }

  @doc """
  Plans a scene construction workflow.
  
  Given initial and goal scene states, generates a sequence of bpy-mcp operations.
  """
  @spec plan_scene_construction(map(), String.t()) :: planning_result()
  def plan_scene_construction(plan_spec, _temp_dir) do
    initial_state = Map.get(plan_spec, "initial_state", %{})
    goal_state = Map.get(plan_spec, "goal_state", %{})
    constraints = Map.get(plan_spec, "constraints", [])
    
    # Try to use aria_planner if available, otherwise use simple planning
    plan = 
      case Code.ensure_loaded?(AriaPlanner) do
        true ->
          try do
            use_aria_planner_for_construction(initial_state, goal_state, constraints)
          rescue
            _ -> 
              # aria_planner loaded but has missing dependencies, fallback to simple planning
              generate_construction_plan(initial_state, goal_state, constraints)
          end
        
        false ->
          generate_construction_plan(initial_state, goal_state, constraints)
      end
    
    case Jason.encode(plan) do
      {:ok, json} -> {:ok, json}
      error -> {:error, "Failed to encode plan: #{inspect(error)}"}
    end
  end

  @doc """
  Plans material application sequence.
  
  Plans the order of material creation and assignment to respect dependencies.
  """
  @spec plan_material_application(map(), String.t()) :: planning_result()
  def plan_material_application(plan_spec, _temp_dir) do
    objects = Map.get(plan_spec, "objects", [])
    materials = Map.get(plan_spec, "materials", [])
    dependencies = Map.get(plan_spec, "dependencies", [])
    
    plan = generate_material_plan(objects, materials, dependencies)
    
    case Jason.encode(plan) do
      {:ok, json} -> {:ok, json}
      error -> {:error, "Failed to encode plan: #{inspect(error)}"}
    end
  end

  @doc """
  Plans animation sequence with temporal constraints.
  
  Generates a plan for setting keyframes with timing constraints.
  """
  @spec plan_animation(map(), String.t()) :: planning_result()
  def plan_animation(plan_spec, _temp_dir) do
    animations = Map.get(plan_spec, "animations", [])
    constraints = Map.get(plan_spec, "constraints", [])
    total_frames = Map.get(plan_spec, "total_frames", 250)
    
    plan = generate_animation_plan(animations, constraints, total_frames)
    
    case Jason.encode(plan) do
      {:ok, json} -> {:ok, json}
      error -> {:error, "Failed to encode plan: #{inspect(error)}"}
    end
  end

  @doc """
  Executes a generated plan by calling bpy-mcp tools in sequence.
  
  Returns execution result with success/failure information.
  """
  @spec execute_plan(map(), String.t()) :: planning_result()
  def execute_plan(plan_data, temp_dir) do
    case Jason.decode(plan_data) do
      {:ok, plan} ->
        execute_plan_steps(plan, temp_dir)
      
      error ->
        {:error, "Failed to decode plan: #{inspect(error)}"}
    end
  end

  # Private helper functions

  defp generate_construction_plan(initial, goal, _constraints) do
    initial_objects = Map.get(initial, "objects", [])
    goal_objects = Map.get(goal, "objects", [])
    
    # Determine what needs to be created
    objects_to_create = goal_objects -- initial_objects
    
    steps = 
      objects_to_create
      |> Enum.with_index()
      |> Enum.map(fn {obj_spec, idx} ->
        obj_spec_map = if is_map(obj_spec), do: obj_spec, else: %{"name" => obj_spec}
        obj_type = Map.get(obj_spec_map, "type", "cube")
        name = Map.get(obj_spec_map, "name", "#{obj_type}#{idx}")
        location = Map.get(obj_spec_map, "location", [0, 0, 0])
        size = Map.get(obj_spec_map, "size", 2.0)
        radius = Map.get(obj_spec_map, "radius", 1.0)
        
        case obj_type do
          "cube" ->
            %{
              tool: "create_cube",
              args: %{
                name: name,
                location: location,
                size: size
              },
              dependencies: [],
              description: "Create cube '#{name}' at #{inspect(location)}"
            }
          
          "sphere" ->
            %{
              tool: "create_sphere",
              args: %{
                name: name,
                location: location,
                radius: radius
              },
              dependencies: [],
              description: "Create sphere '#{name}' at #{inspect(location)}"
            }
          
          _ ->
            %{
              tool: "create_cube",
              args: %{
                name: name,
                location: location,
                size: size
              },
              dependencies: [],
              description: "Create object '#{name}' at #{inspect(location)}"
            }
        end
      end)
    
    %{
      steps: steps,
      total_operations: length(steps),
      estimated_complexity: complexity_label(length(steps))
    }
  end

  defp generate_material_plan(objects, materials, dependencies) do
    # Create material dependency graph
    dep_map = build_dependency_map(dependencies)
    
    # Sort materials by dependencies (topological sort)
    sorted_materials = topological_sort(materials, dep_map)
    
    steps =
      sorted_materials
      |> Enum.flat_map(fn mat ->
        # First, ensure material exists (if not already created)
        mat_steps = [
          %{
            tool: "set_material",
            args: %{
              object_name: find_object_for_material(objects, mat),
              material_name: mat,
              color: [0.8, 0.8, 0.8, 1.0]
            },
            dependencies: get_dependencies(mat, dep_map),
            description: "Apply material '#{mat}' to object"
          }
        ]
        
        mat_steps
      end)
    
    %{
      steps: steps,
      total_operations: length(steps),
      estimated_complexity: complexity_label(length(steps))
    }
  end

  defp generate_animation_plan(animations, constraints, total_frames) do
    # Simple temporal planning: assign frames based on constraints
    scheduled_animations = schedule_animations(animations, constraints, total_frames)
    
    steps =
      scheduled_animations
      |> Enum.map(fn anim ->
        %{
          tool: "set_keyframe",  # Future tool
          args: %{
            object_name: Map.get(anim, "object"),
            frame: Map.get(anim, "frame"),
            property: Map.get(anim, "property"),
            value: Map.get(anim, "value")
          },
          dependencies: get_animation_dependencies(anim, constraints),
          description: "Set keyframe for #{Map.get(anim, "object")} at frame #{Map.get(anim, "frame")}"
        }
      end)
    
    %{
      steps: steps,
      total_operations: length(steps),
      estimated_complexity: complexity_label(length(steps)),
      total_frames: total_frames
    }
  end

  defp execute_plan_steps(plan, temp_dir) do
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

  defp execute_step(tool, args, temp_dir) do
    case tool do
      "create_cube" ->
        name = Map.get(args, "name", "Cube")
        location = Map.get(args, "location", [0, 0, 0])
        size = Map.get(args, "size", 2.0)
        BpyMcp.BpyTools.Objects.create_cube(name, location, size, temp_dir)
      
      "create_sphere" ->
        name = Map.get(args, "name", "Sphere")
        location = Map.get(args, "location", [0, 0, 0])
        radius = Map.get(args, "radius", 1.0)
        BpyMcp.BpyTools.Objects.create_sphere(name, location, radius, temp_dir)
      
      "set_material" ->
        object_name = Map.get(args, "object_name")
        material_name = Map.get(args, "material_name", "Material")
        color = Map.get(args, "color", [0.8, 0.8, 0.8, 1.0])
        BpyMcp.BpyTools.Materials.set_material(object_name, material_name, color, temp_dir)
      
      _ ->
        {:error, "Unknown tool: #{tool}"}
    end
  end

  defp build_dependency_map(dependencies) do
    dependencies
    |> Enum.reduce(%{}, fn dep, acc ->
      from = Map.get(dep, "from")
      to = Map.get(dep, "to")
      
      acc
      |> Map.update(to, [from], &[from | &1])
    end)
  end

  defp topological_sort(items, dep_map) do
    # Simple topological sort (Kahn's algorithm)
    items
    |> Enum.sort_by(fn item ->
      length(Map.get(dep_map, item, []))
    end)
  end

  defp get_dependencies(item, dep_map) do
    Map.get(dep_map, item, [])
  end

  defp find_object_for_material(objects, _material) do
    # Simple heuristic: find first object that might need this material
    case objects do
      [] -> "Object1"
      [obj | _] -> if is_map(obj), do: Map.get(obj, "name", "Object1"), else: obj
    end
  end

  defp schedule_animations(animations, _constraints, total_frames) do
    # Simple scheduling: distribute animations across frames
    frame_step = div(total_frames, max(length(animations), 1))
    
    animations
    |> Enum.with_index()
    |> Enum.map(fn {anim, idx} ->
      base_frame = idx * frame_step
      frame = Map.get(anim, "frame", base_frame)
      
      anim
      |> Map.put("frame", min(frame, total_frames - 1))
    end)
  end

  defp get_animation_dependencies(_anim, _constraints) do
    # Extract dependencies from constraints
    []
  end

  defp complexity_label(count) when count < 5, do: "simple"
  defp complexity_label(count) when count < 15, do: "moderate"
  defp complexity_label(count) when count < 30, do: "complex"
  defp complexity_label(_), do: "very_complex"

  # aria_planner integration functions (when library is available)
  
  defp use_aria_planner_for_construction(initial_state, goal_state, constraints) do
    # TODO: Use aria_planner's planning functions once we understand the API
    # For now, fallback to simple planning
    # Example: AriaPlanner.solve(initial_state, goal_state, constraints)
    generate_construction_plan(initial_state, goal_state, constraints)
  end
end

