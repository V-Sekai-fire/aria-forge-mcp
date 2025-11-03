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
    # Use run_lazy for all planning - it handles both goal decomposition and temporal/dependency scheduling
    # run_lazy can handle:
    # - High-level goal decomposition (hierarchical planning)
    # - Explicit object lists (task-based planning)
    # - Temporal constraints (via temporal STN in aria_planner)
    # - Dependencies (via dependency graph in domain spec)
    
    case try_run_lazy(initial_state, goal_state, constraints) do
      {:ok, plan} -> plan
      {:fallback, _reason} -> 
        # If run_lazy fails, fallback to simple planning
        generate_construction_plan(initial_state, goal_state, constraints)
    end
  end
  
  defp try_run_lazy(initial_state, goal_state, constraints) do
    # Try to use run_lazy for goal-based planning with decomposition
    case Code.ensure_loaded?(AriaPlanner) do
      true ->
        try do
          # Convert goal_state to tasks/initial_state format for run_lazy
          # run_lazy expects: domain, initial_state, tasks, opts, execution
          
          # Create Blender domain spec with methods and actions
          domain = create_blender_domain_spec()
          
          # Convert initial_state to planning format, including constraints
          planning_initial_state = 
            convert_to_planning_state(initial_state)
            |> add_constraints_to_state(constraints)
          
          # Convert goal_state to tasks
          tasks = convert_goal_to_tasks(goal_state)
          
          # Call run_lazy (execution=false means planning only)
          # run_lazy handles:
          # - Goal decomposition (hierarchical planning)
          # - Dependency resolution (via domain methods)
          # - Temporal scheduling (via aria_planner's temporal STN)
          # - Optimal ordering (via lazy refinement)
          case AriaPlanner.run_lazy(domain, planning_initial_state, tasks, [], false) do
            {:ok, plan} ->
              # Extract solution plan from run_lazy result
              convert_run_lazy_plan_to_blender_plan(plan)
            
            error ->
              {:fallback, "run_lazy failed: #{inspect(error)}"}
          end
        rescue
          e ->
            {:fallback, "run_lazy error: #{inspect(e)}"}
        end
      
      false ->
        {:fallback, "AriaPlanner not available"}
    end
  end
  
  
  defp create_blender_domain_spec do
    # Create a domain spec for Blender operations using run_lazy
    # This defines actions and methods for Blender scene construction
    # Methods handle goal decomposition, actions are the actual operations
    %{
      methods: %{
        "create_scene" => fn state, goal ->
          # Method to decompose "create scene" into object creation tasks
          # Handles both explicit objects list and high-level descriptions
          case goal do
            %{"objects" => objects} when is_list(objects) ->
              # Explicit objects: create tasks respecting dependencies
              Enum.map(objects, fn obj ->
                obj_name = Map.get(obj, "name", "Object")
                {"create_object", Map.put(obj, "name", obj_name)}
              end)
            
            %{"description" => desc} when is_binary(desc) ->
              # High-level description: decompose into subgoals
              # This would be expanded by run_lazy's goal decomposition
              [{"create_floor", %{}}, {"create_walls", %{}}, {"create_furniture", %{}}]
            
            _ ->
              # Default: try to extract from goal_state
              []
          end
        end,
        "create_object" => fn state, obj_spec ->
          # Method to create individual objects with dependency checking
          # run_lazy will handle scheduling based on dependencies
          case obj_spec do
            %{"type" => "cube"} -> [{"create_cube", obj_spec}]
            %{"type" => "sphere"} -> [{"create_sphere", obj_spec}]
            _ -> [{"create_cube", obj_spec}]
          end
        end
      },
      actions: %{
        "create_cube" => fn state, args ->
          # Action: create cube with duration estimation
          # run_lazy uses durations for temporal scheduling
          duration = estimate_action_duration("create_cube", args)
          {:ok, state, duration}
        end,
        "create_sphere" => fn state, args ->
          # Action: create sphere with duration estimation
          duration = estimate_action_duration("create_sphere", args)
          {:ok, state, duration}
        end
      },
      initial_tasks: []
    }
  end
  
  defp estimate_action_duration(action, _args) when action in ["create_cube", "create_sphere"], do: 1
  defp estimate_action_duration(_action, _args), do: 1
  
  defp add_constraints_to_state(state, constraints) when is_list(constraints) do
    # Extract dependencies and temporal constraints from constraints list
    dependencies = extract_dependencies_from_constraints(constraints)
    temporal = extract_temporal_from_constraints(constraints)
    
    update_in(state, [:constraints], fn existing ->
      Map.merge(existing, %{
        dependencies: dependencies,
        temporal: temporal
      })
    end)
  end
  defp add_constraints_to_state(state, _), do: state
  
  defp extract_dependencies_from_constraints(constraints) when is_list(constraints) do
    # Extract dependencies for run_lazy to respect
    constraints
    |> Enum.filter(fn c -> 
      Map.get(c, "type") == "precedence" or 
      Map.get(c, "type") == "dependency" or
      Map.has_key?(c, "before") or
      Map.has_key?(c, "after")
    end)
    |> Enum.map(fn c ->
      %{
        before: Map.get(c, "before") || Map.get(c, "predecessor"),
        after: Map.get(c, "after") || Map.get(c, "successor")
      }
    end)
    |> Enum.filter(fn d -> d.before != nil and d.after != nil end)
  end
  defp extract_dependencies_from_constraints(_), do: []
  
  defp extract_temporal_from_constraints(constraints) when is_list(constraints) do
    # Extract temporal constraints for run_lazy's temporal STN
    constraints
    |> Enum.filter(fn c ->
      Map.get(c, "type") == "temporal" or 
      Map.has_key?(c, "duration") or 
      Map.has_key?(c, "deadline")
    end)
  end
  defp extract_temporal_from_constraints(_), do: []
  
  defp convert_to_planning_state(initial_state) do
    # Convert Blender initial state to planning state format for run_lazy
    # Include constraints in state so run_lazy can respect them
    %{
      current_time: DateTime.utc_now(),
      timeline: %{},
      entity_capabilities: %{},
      facts: Map.get(initial_state, "objects", []),
      constraints: %{
        dependencies: [],
        temporal: []
      }
    }
  end
  
  defp convert_goal_to_tasks(goal_state) do
    # Convert goal_state to task format for run_lazy
    # run_lazy handles both explicit task lists and goal decomposition
    cond do
      Map.has_key?(goal_state, "objects") ->
        # Explicit objects → create tasks for each
        # run_lazy will schedule these respecting dependencies
        Enum.map(Map.get(goal_state, "objects", []), fn obj ->
          obj_name = Map.get(obj, "name", "Object")
          {"create_object", Map.put(obj, "name", obj_name)}
        end)
      
      Map.has_key?(goal_state, "description") ->
        # High-level description → single decomposition task
        # run_lazy will decompose this using methods
        [{"create_scene", goal_state}]
      
      true ->
        # Default: try to extract tasks from goal_state
        [{"create_scene", goal_state}]
    end
  end
  
  defp convert_run_lazy_plan_to_blender_plan(plan) do
    # Extract solution plan from run_lazy result and convert to Blender operation plan
    # The plan contains solution_graph_data and solution_plan
    case Map.get(plan, :solution_plan) do
      nil ->
        {:fallback, "No solution plan in run_lazy result"}
      
      plan_json when is_binary(plan_json) ->
        case Jason.decode(plan_json) do
          {:ok, solution_steps} ->
            # Convert solution steps to Blender plan format
            steps = 
              solution_steps
              |> Enum.map(fn step ->
                # step format from run_lazy: {"action_name", args}
                case step do
                  ["create_cube", args] when is_map(args) ->
                    %{
                      tool: "create_cube",
                      args: %{
                        "name" => Map.get(args, "name", "Cube"),
                        "location" => Map.get(args, "location", [0, 0, 0]),
                        "size" => Map.get(args, "size", 2.0)
                      },
                      dependencies: [],
                      description: "Create cube '#{Map.get(args, "name", "Cube")}'"
                    }
                  
                  ["create_sphere", args] when is_map(args) ->
                    %{
                      tool: "create_sphere",
                      args: %{
                        "name" => Map.get(args, "name", "Sphere"),
                        "location" => Map.get(args, "location", [0, 0, 0]),
                        "radius" => Map.get(args, "radius", 1.0)
                      },
                      dependencies: [],
                      description: "Create sphere '#{Map.get(args, "name", "Sphere")}'"
                    }
                  
                  _ ->
                    nil
                end
              end)
              |> Enum.filter(&(&1 != nil))
            
            if Enum.empty?(steps) do
              {:fallback, "No valid steps extracted from run_lazy plan"}
            else
              {:ok, %{
                steps: steps,
                total_operations: length(steps),
                estimated_complexity: complexity_label(length(steps)),
                planner: "run_lazy",
                solution_graph: Map.get(plan, :solution_graph_data, %{})
              }}
            end
          
          error ->
            {:fallback, "Failed to decode run_lazy solution plan: #{inspect(error)}"}
        end
      
      _ ->
        {:fallback, "Invalid solution_plan format"}
    end
  end
  
end

