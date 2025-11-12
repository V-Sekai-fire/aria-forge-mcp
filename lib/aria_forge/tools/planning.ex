# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Planning do
  @moduledoc """
  Planning tools for generating sequences of commands.

  These tools help plan complex workflows by generating ordered sequences
  of aria-forge commands that respect dependencies and constraints.

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
          total_operations: integer()
        }

  @doc """
  Generic run_lazy planning function.

  Handles any planning scenario with goal decomposition, dependencies, temporal constraints, and custom domains.
  """
  @spec run_lazy_planning(map(), String.t()) :: planning_result()
  def run_lazy_planning(plan_spec, _temp_dir) do
    initial_state = Map.get(plan_spec, "initial_state", %{})
    tasks = Map.get(plan_spec, "tasks", [])
    constraints = Map.get(plan_spec, "constraints", [])
    custom_domain = Map.get(plan_spec, "domain")
    opts = Map.get(plan_spec, "opts", %{})

    # Try to use aria_planner if available
    plan =
      case Code.ensure_loaded?(AriaPlanner) do
        true ->
          try do
            # Use custom domain if provided, otherwise use default domain
            domain =
              if custom_domain != nil do
                convert_domain_spec_from_json(custom_domain)
              else
                create_scene_domain_spec()
              end

            # Convert initial_state to planning format, including constraints
            planning_initial_state =
              convert_to_planning_state(initial_state)
              |> add_constraints_to_state(constraints)

            # Tasks can be provided directly or need conversion
            planning_tasks =
              if is_list(tasks) and length(tasks) > 0 do
                # Tasks are provided as list of {task_name, args} tuples or strings
                Enum.map(tasks, fn task ->
                  case task do
                    [name, args] when is_binary(name) -> {name, args}
                    %{"task" => name, "args" => args} -> {name, args}
                    name when is_binary(name) -> {name, %{}}
                    _ -> task
                  end
                end)
              else
                []
              end

            # Convert opts to keyword list for run_lazy
            planning_opts =
              opts
              |> Map.to_list()
              |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

            # Determine execution mode (default false = planning only)
            execution = Map.get(opts, "execution", false)

            # Call run_lazy
            case AriaPlanner.run_lazy(domain, planning_initial_state, planning_tasks, planning_opts, execution) do
              {:ok, plan_result} ->
                # Extract solution plan from run_lazy result
                convert_run_lazy_plan_to_scene_plan(plan_result)

              error ->
                {:error, "run_lazy failed: #{inspect(error)}"}
            end
          rescue
            e ->
              {:error, "run_lazy error: #{inspect(e)}"}
          end

        false ->
          {:error, "AriaPlanner not available. Planning requires aria_planner to be installed and available."}
      end

    case plan do
      {:error, _} = error ->
        error
      plan_map when is_map(plan_map) ->
        case Jason.encode(plan_map) do
          {:ok, json} -> {:ok, json}
          error -> {:error, "Failed to encode plan: #{inspect(error)}"}
        end
      other ->
        {:error, "Unexpected planning result: #{inspect(other)}"}
    end
  end

  @doc """
  Plans a scene construction workflow.

  Given initial and goal scene states, generates a sequence of aria-forge commands.
  Requires aria_planner to be available.
  """
  @spec plan_scene_construction(map(), String.t()) :: planning_result()
  def plan_scene_construction(plan_spec, temp_dir) do
    initial_state = Map.get(plan_spec, "initial_state", %{})
    goal_state = Map.get(plan_spec, "goal_state", %{})
    constraints = Map.get(plan_spec, "constraints", [])

    # Convert to run_lazy_planning format
    run_lazy_spec = %{
      "initial_state" => initial_state,
      "tasks" => convert_goal_to_tasks(goal_state),
      "constraints" => constraints,
      "domain" => nil,
      "opts" => %{}
    }

    run_lazy_planning(run_lazy_spec, temp_dir)
  end

  @doc """
  Plans material application sequence.

  Plans the order of material creation and assignment to respect dependencies.
  Requires aria_planner to be available.
  """
  @spec plan_material_application(map(), String.t()) :: planning_result()
  def plan_material_application(plan_spec, temp_dir) do
    objects = Map.get(plan_spec, "objects", [])
    materials = Map.get(plan_spec, "materials", [])
    dependencies = Map.get(plan_spec, "dependencies", [])

    # Convert to run_lazy_planning format
    tasks = Enum.map(materials, fn mat ->
      mat_name = Map.get(mat, "name", "Material")
      {"apply_materials", %{"materials" => [mat], "objects" => objects}}
    end)

    run_lazy_spec = %{
      "initial_state" => %{"facts" => objects},
      "tasks" => tasks,
      "constraints" => dependencies,
      "domain" => nil,
      "opts" => %{}
    }

    run_lazy_planning(run_lazy_spec, temp_dir)
  end

  @doc """
  Plans animation sequence with temporal constraints.

  Generates a plan for setting keyframes with timing constraints.
  Requires aria_planner to be available.
  """
  @spec plan_animation(map(), String.t()) :: planning_result()
  def plan_animation(plan_spec, temp_dir) do
    animations = Map.get(plan_spec, "animations", [])
    constraints = Map.get(plan_spec, "constraints", [])
    total_frames = Map.get(plan_spec, "total_frames", 250)

    # Convert to run_lazy_planning format with temporal constraints
    tasks = Enum.map(animations, fn anim ->
      {"set_keyframe", anim}
    end)

    # Add temporal constraints for frame timing
    temporal_constraints = [
      %{
        "type" => "temporal",
        "total_frames" => total_frames
      }
      | constraints
    ]

    run_lazy_spec = %{
      "initial_state" => %{
        "facts" => [],
        "timeline" => %{"total_frames" => total_frames}
      },
      "tasks" => tasks,
      "constraints" => temporal_constraints,
      "domain" => nil,
      "opts" => %{}
    }

    run_lazy_planning(run_lazy_spec, temp_dir)
  end

  @doc """
  Executes a generated plan by calling aria-forge tools in sequence.

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
    # Record start time
    start_time = System.monotonic_time(:millisecond)
    
    result = case tool do
      "create_cube" ->
        name = Map.get(args, "name", "Cube")
        location = Map.get(args, "location", [0, 0, 0])
        size = Map.get(args, "size", 2.0)
        AriaForge.Tools.Objects.create_cube(name, location, size, temp_dir)

      "create_sphere" ->
        name = Map.get(args, "name", "Sphere")
        location = Map.get(args, "location", [0, 0, 0])
        radius = Map.get(args, "radius", 1.0)
        AriaForge.Tools.Objects.create_sphere(name, location, radius, temp_dir)

      "set_material" -> 
        object_name = Map.get(args, "object_name")
        material_name = Map.get(args, "material_name", "Material")
        color = Map.get(args, "color", [0.8, 0.8, 0.8, 1.0])
        AriaForge.Tools.Materials.set_material(object_name, material_name, color, temp_dir)

      "introspect_blender" ->
        object_path = Map.get(args, "object_path", "bmesh")
        AriaForge.Tools.Introspection.introspect_blender(object_path, temp_dir)

      "introspect_python" ->
        object_path = Map.get(args, "object_path", "json")
        prep_code = Map.get(args, "prep_code", nil)
        AriaForge.Tools.Introspection.introspect_python(object_path, prep_code, temp_dir)

      "reset_scene" ->
        AriaForge.Tools.Scene.reset_scene(temp_dir)

      "get_scene_info" ->
        AriaForge.Tools.Scene.get_scene_info(temp_dir)

      _ ->
        {:error, "Unknown tool: #{tool}"}
    end
    
    # Record end time and calculate duration
    end_time = System.monotonic_time(:millisecond)
    duration_ms = end_time - start_time
    duration_seconds = duration_ms / 1000.0
    duration_iso = seconds_to_iso_duration(duration_seconds)
    
    # Return result with duration information
    case result do
      {:ok, message} ->
        {:ok, "#{message} (duration: #{duration_iso})"}
      error ->
        error
    end
  end

  @doc """
  Creates a comprehensive forge planner domain specification.

  This domain includes all forge operations: object creation, materials, scene management, and rendering.
  It provides methods for goal decomposition and commands for primitive operations.
  """
  @spec create_forge_domain_spec() :: map()
  def create_forge_domain_spec do
    # Create a comprehensive domain spec for all forge operations using run_lazy
    # This defines methods (goal decomposition) and commands (primitive operations)
    %{
      methods: %{
        "create_forge_scene" => fn _state, goal ->
          # Method to decompose "create forge scene" into complete workflow
          # Handles objects, materials, and rendering setup
          tasks = []
          
          # Check if we need to reset scene first
          if Map.get(goal, "reset_first", false) do
            tasks = [{"reset_scene", %{}}]
          end
          
          # Optionally introspect scene before creating
          if Map.get(goal, "introspect_first", false) do
            tasks = tasks ++ [{"get_scene_info", %{}}]
          end

          # Extract objects to create
          objects = Map.get(goal, "objects", [])
          tasks = if length(objects) > 0 do
            tasks ++ Enum.map(objects, fn obj -> {"create_object", obj} end)
          else
            tasks
          end

          # Extract materials to apply
          materials = Map.get(goal, "materials", [])
          tasks = if length(materials) > 0 do
            tasks ++ [{"apply_materials", %{"materials" => materials}}]
          else
            tasks
          end

          # Extract rendering requirements
          tasks = if Map.has_key?(goal, "render") do
            tasks ++ [{"prepare_rendering", Map.get(goal, "render", %{})}]
          else
            tasks
          end

          if Enum.empty?(tasks) do
            # Fallback to basic scene creation
            [{"create_scene", goal}]
          else
            tasks
          end
        end,
        "create_scene" => fn _state, goal ->
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
        "create_object" => fn _state, obj_spec ->
          # Method to create individual objects with dependency checking
          # run_lazy will handle scheduling based on dependencies
          case obj_spec do
            %{"type" => "cube"} -> [{"create_cube", obj_spec}]
            %{"type" => "sphere"} -> [{"create_sphere", obj_spec}]
            _ -> [{"create_cube", obj_spec}]
          end
        end,
        "apply_materials" => fn _state, material_spec ->
          # Method to decompose material application workflow
          # Handles material creation and assignment to objects
          materials = Map.get(material_spec, "materials", [])
          objects = Map.get(material_spec, "objects", [])

          Enum.flat_map(materials, fn mat ->
            mat_name = Map.get(mat, "name", "Material")
            target_objects = Map.get(mat, "objects", objects)

            Enum.map(target_objects, fn obj_name ->
              obj_name_str = if is_map(obj_name), do: Map.get(obj_name, "name", "Object"), else: obj_name
              {"set_material", %{"object_name" => obj_name_str, "material_name" => mat_name, "color" => Map.get(mat, "color", [0.8, 0.8, 0.8, 1.0])}}
            end)
          end)
        end,
        "setup_materials" => fn _state, material_spec ->
          # Method to setup materials (alias for apply_materials)
          # Reuse the same logic as apply_materials
          materials = Map.get(material_spec, "materials", [])
          objects = Map.get(material_spec, "objects", [])

          Enum.flat_map(materials, fn mat ->
            mat_name = Map.get(mat, "name", "Material")
            target_objects = Map.get(mat, "objects", objects)

            Enum.map(target_objects, fn obj_name ->
              obj_name_str = if is_map(obj_name), do: Map.get(obj_name, "name", "Object"), else: obj_name
              {"set_material", %{"object_name" => obj_name_str, "material_name" => mat_name, "color" => Map.get(mat, "color", [0.8, 0.8, 0.8, 1.0])}}
            end)
          end)
        end,
        "prepare_rendering" => fn _state, render_spec ->
          # Method to prepare rendering workflow
          # Ensures scene is ready before rendering
          filepath = Map.get(render_spec, "filepath", "render.png")
          resolution_x = Map.get(render_spec, "resolution_x", 1920)
          resolution_y = Map.get(render_spec, "resolution_y", 1080)

          [
            {"get_scene_info", %{}},
            {"render_image", %{"filepath" => filepath, "resolution_x" => resolution_x, "resolution_y" => resolution_y}}
          ]
        end,
        "explore_blender_api" => fn _state, api_spec ->
          # Method to decompose Blender API exploration into introspection steps
          # When connected via MCP, this plans steps to introspect Blender's API
          paths = Map.get(api_spec, "paths", ["bmesh"])
          prep_code = Map.get(api_spec, "prep_code", nil)

          Enum.map(paths, fn path ->
            if prep_code != nil do
              {"introspect_python", %{"object_path" => path, "prep_code" => prep_code}}
            else
              {"introspect_blender", %{"object_path" => path}}
            end
          end)
        end,
        "introspect_blender_api" => fn _state, api_spec ->
          # Method alias for exploring Blender API
          # Reuse the same logic as explore_blender_api
          paths = Map.get(api_spec, "paths", ["bmesh"])
          prep_code = Map.get(api_spec, "prep_code", nil)

          Enum.map(paths, fn path ->
            if prep_code != nil do
              {"introspect_python", %{"object_path" => path, "prep_code" => prep_code}}
            else
              {"introspect_blender", %{"object_path" => path}}
            end
          end)
        end,
        "discover_blender_capabilities" => fn _state, _spec ->
          # Method to discover Blender capabilities via introspection
          # Plans a sequence of introspection steps for common Blender API paths
          common_paths = [
            "bmesh",
            "bmesh.ops",
            "bpy",
            "bpy.context",
            "bpy.data",
            "bpy.ops"
          ]

          Enum.map(common_paths, fn path ->
            {"introspect_blender", %{"object_path" => path}}
          end)
        end,
        "introspect_scene" => fn _state, _spec ->
          # Method to introspect the current scene state
          # Gets information about objects, materials, and scene configuration
          [{"get_scene_info", %{}}]
        end,
        "reset_and_prepare_scene" => fn _state, goal ->
          # Method to reset scene and then prepare it for new work
          # Useful when starting fresh or clearing existing content
          tasks = [{"reset_scene", %{}}]
          
          # If goal specifies objects or materials, add those after reset
          objects = Map.get(goal, "objects", [])
          if length(objects) > 0 do
            tasks = tasks ++ Enum.map(objects, fn obj -> {"create_object", obj} end)
          end
          
          materials = Map.get(goal, "materials", [])
          if length(materials) > 0 do
            tasks = tasks ++ [{"apply_materials", %{"materials" => materials}}]
          end
          
          tasks
        end,
        "prepare_clean_scene" => fn _state, goal ->
          # Method alias for reset_and_prepare_scene
          reset_fn = Map.get(create_forge_domain_spec().methods, "reset_and_prepare_scene")
          reset_fn.(_state, goal)
        end
      },
      commands: %{
        "create_cube" => fn state, _args ->
          # Command: create cube
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "create_sphere" => fn state, _args ->
          # Command: create sphere
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "set_material" => fn state, _args ->
          # Command: set material on object
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "reset_scene" => fn state, _args ->
          # Command: reset scene to clean state
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "get_scene_info" => fn state, _args ->
          # Command: get scene information
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "render_image" => fn state, _args ->
          # Command: render scene to image
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "introspect_blender" => fn state, _args ->
          # Command: introspect Blender/bmesh API structure
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "introspect_python" => fn state, _args ->
          # Command: introspect Python object/API structure
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end
      },
      initial_tasks: []
    }
  end

  defp create_scene_domain_spec do
    # Create a domain spec for commands using run_lazy
    # This defines commands and methods for scene construction
    # Methods handle goal decomposition, commands are the actual primitives we call
    %{
      methods: %{
        "create_scene" => fn _state, goal ->
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
        "create_object" => fn _state, obj_spec ->
          # Method to create individual objects with dependency checking
          # run_lazy will handle scheduling based on dependencies
          case obj_spec do
            %{"type" => "cube"} -> [{"create_cube", obj_spec}]
            %{"type" => "sphere"} -> [{"create_sphere", obj_spec}]
            _ -> [{"create_cube", obj_spec}]
          end
        end
      },
      commands: %{
        "create_cube" => fn state, _args ->
          # Command: create cube
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end,
        "create_sphere" => fn state, _args ->
          # Command: create sphere
          # Duration will be recorded during actual execution
          {:ok, state, "PT1S"}
        end
      },
      initial_tasks: []
    }
  end

  @doc """
  Converts seconds to ISO 8601 duration string.
  
  Examples:
  - 1 second -> "PT1S"
  - 30 seconds -> "PT30S"
  - 90 seconds -> "PT1M30S"
  - 3600 seconds -> "PT1H"
  """
  defp seconds_to_iso_duration(seconds) when is_float(seconds) or is_integer(seconds) do
    total_seconds = trunc(seconds)
    
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    secs = rem(total_seconds, 60)
    
    parts = []
    parts = if hours > 0, do: ["#{hours}H" | parts], else: parts
    parts = if minutes > 0, do: ["#{minutes}M" | parts], else: parts
    parts = if secs > 0, do: ["#{secs}S" | parts], else: parts
    
    # Always include at least seconds, even if 0
    if Enum.empty?(parts), do: "PT0S", else: "PT" <> Enum.join(parts)
  end

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
    # Convert initial state to planning state format for run_lazy
    # Include constraints in state so run_lazy can respect them
    # If initial_state already has required keys, use them; otherwise use defaults
    base_state = %{
      current_time: DateTime.utc_now(),
      timeline: Map.get(initial_state, "timeline", %{}),
      entity_capabilities: Map.get(initial_state, "entity_capabilities", %{}),
      facts: Map.get(initial_state, "facts", Map.get(initial_state, "objects", [])),
      constraints: %{
        dependencies: [],
        temporal: []
      }
    }

    # Merge with any existing constraints in initial_state
    if Map.has_key?(initial_state, "constraints") do
      Map.update!(base_state, :constraints, fn existing ->
        Map.merge(existing, initial_state["constraints"])
      end)
    else
      base_state
    end
  end

  defp convert_domain_spec_from_json(domain_json) when is_map(domain_json) do
    # Convert JSON domain specification to Elixir format for run_lazy
    # For custom domains provided via JSON, we use the default domain
    # as a base since we can't dynamically create Elixir functions from JSON
    # Full implementation would require a domain language or function registry
    # Note: JSON may use "actions" but internally we use "commands"
    create_scene_domain_spec()
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

  defp convert_run_lazy_plan_to_scene_plan(plan) do
    # Extract solution plan from run_lazy result and convert to command plan
    # The plan contains solution_graph_data and solution_plan
    case Map.get(plan, :solution_plan) do
      nil ->
        {:fallback, "No solution plan in run_lazy result"}

      plan_json when is_binary(plan_json) ->
        case Jason.decode(plan_json) do
          {:ok, solution_steps} ->
            # Convert solution steps to plan format
            steps =
              solution_steps
              |> Enum.map(fn step ->
                # step format from run_lazy: {command_name, args}
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
              {:ok,
               %{
                 steps: steps,
                 total_operations: length(steps),
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
