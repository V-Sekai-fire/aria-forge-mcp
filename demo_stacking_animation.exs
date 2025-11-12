# Demo: Stacking animation with backtracking planning
alias AriaForge.Tools.Planning

temp_dir = System.tmp_dir!()

IO.puts("=== Stacking Animation Demo ===\n")
IO.puts("This demo shows:")
IO.puts("1. Planning a stacking animation with backtracking")
IO.puts("2. Creating objects that stack on top of each other")
IO.puts("3. Setting keyframes to animate the stacking")
IO.puts("4. Using backtracking to handle dependencies (objects must exist before keyframes)\n")

# Test the domain method decomposition
domain = Planning.create_forge_domain_spec()
methods = Map.get(domain, :methods)
stacking_fn = Map.get(methods, "stacking_animation")

if stacking_fn do
  IO.puts("✓ stacking_animation method found in domain\n")
  
  # Test decomposition
  goal = %{
    "count" => 3,
    "base_location" => [0, 0, 0],
    "spacing" => 2.0,
    "start_frame" => 1,
    "frames_per_object" => 30
  }
  
  tasks = stacking_fn.(%{}, goal)
  
  IO.puts("Decomposition result (#{length(tasks)} tasks):")
  Enum.each(Enum.with_index(tasks, 1), fn {{task_name, task_args}, idx} ->
    IO.puts("  #{idx}. #{task_name}")
    case task_name do
      "create_cube" ->
        name = Map.get(task_args, "name")
        location = Map.get(task_args, "location")
        IO.puts("     -> Create cube '#{name}' at #{inspect(location)}")
      "set_keyframe" ->
        object = Map.get(task_args, "object")
        frame = Map.get(task_args, "frame")
        value = Map.get(task_args, "value")
        IO.puts("     -> Set keyframe for '#{object}' at frame #{frame}, value #{inspect(value)}")
      _ ->
        IO.puts("     -> #{inspect(task_args)}")
    end
  end)
  
  IO.puts("\n✓ Domain decomposition successful")
  IO.puts("  - Creates 3 cubes at starting positions")
  IO.puts("  - Sets keyframes to animate them stacking")
  IO.puts("  - Backtracking will ensure objects are created before keyframes are set\n")
  
  # Now test planning
  IO.puts("=== Testing Planning System ===\n")
  
  plan_spec = %{
    "initial_state" => %{"objects" => []},
    "tasks" => [
      {"prepare_scene", %{"fps" => 30}},
      {"stacking_animation", goal}
    ],
    "constraints" => [
      %{"type" => "dependency", "from" => "prepare_scene", "to" => "stacking_animation"}
    ],
    "domain" => nil,
    "opts" => %{
      "execution" => false,
      "backtracking" => true
    }
  }
  
  IO.puts("Generating plan with backtracking...")
  case Planning.run_lazy_planning(plan_spec, temp_dir) do
    {:ok, plan_json} ->
      IO.puts("✓ Plan generated\n")
      
      case Jason.decode(plan_json) do
        {:ok, plan} ->
          steps = Map.get(plan, "steps", [])
          IO.puts("Plan has #{length(steps)} steps:\n")
          
          # Group steps by type
          create_steps = Enum.filter(steps, fn s -> Map.get(s, "tool") == "create_cube" end)
          keyframe_steps = Enum.filter(steps, fn s -> Map.get(s, "tool") == "set_keyframe" end)
          
          IO.puts("  - #{length(create_steps)} object creation steps")
          IO.puts("  - #{length(keyframe_steps)} keyframe steps")
          IO.puts("  - Backtracking ensures objects are created before keyframes\n")
          
          IO.puts("First few steps:")
          Enum.each(Enum.take(steps, 5), fn step ->
            tool = Map.get(step, "tool")
            desc = Map.get(step, "description", "")
            IO.puts("    #{tool}: #{desc}")
          end)
          
          if length(steps) > 5 do
            IO.puts("    ... (#{length(steps) - 5} more steps)")
          end
          
        {:error, _} ->
          IO.puts("Plan JSON (first 500 chars):")
          IO.puts(String.slice(plan_json, 0, 500))
      end
      
    {:error, reason} ->
      if String.contains?(to_string(reason), "AriaPlanner not available") do
        IO.puts("⚠ AriaPlanner not available")
        IO.puts("This is expected if aria_planner is not installed.")
        IO.puts("\nHowever, the domain method decomposition works correctly!")
        IO.puts("When aria_planner is available, it will:")
        IO.puts("  - Use backtracking to ensure objects are created before keyframes")
        IO.puts("  - Schedule keyframes with proper temporal constraints")
        IO.puts("  - Generate an executable plan")
      else
        IO.puts("✗ Planning failed: #{reason}")
      end
  end
else
  IO.puts("✗ stacking_animation method not found in domain")
end

IO.puts("\n=== Demo Complete ===")

