# Run planner and show the plan for stacking animation
# This uses the NativeService to call the planning system

# We need to start the application first
case Code.ensure_loaded(Mix) do
  {:module, Mix} ->
    Mix.install([])
  _ ->
    :ok
end

# Try to start the application
try do
  Application.ensure_all_started(:aria_forge)
rescue
  _ -> :ok
end

alias AriaForge.NativeService
alias AriaForge.Tools.Planning

IO.puts("=== Running Planner for Stacking Animation ===\n")

# Create plan spec
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"prepare_scene", %{"fps" => 30}},
    {"stacking_animation", %{
      "count" => 3,
      "base_location" => [0, 0, 0],
      "spacing" => 2.0,
      "start_frame" => 1,
      "frames_per_object" => 30
    }}
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

IO.puts("Plan Specification:")
IO.puts("  Tasks: prepare_scene, stacking_animation")
IO.puts("  Constraints: prepare_scene -> stacking_animation")
IO.puts("  Backtracking: enabled\n")

# Try to use NativeService
IO.puts("Calling run_lazy planner via NativeService...\n")

try do
  args = %{"plan_spec" => plan_spec}
  result = NativeService.handle_tool_call("run_lazy", args, %{})
  
  case result do
    {:ok, %{content: [%{"text" => text}]}, _state} ->
      IO.puts("✓ Planning successful!\n")
      IO.puts(String.duplicate("=", 70))
      IO.puts("PLAN RESULT:")
      IO.puts(String.duplicate("=", 70))
      IO.puts(text)
      IO.puts(String.duplicate("=", 70))
      
      # Try to extract and parse the plan
      json_match = Regex.run(~r/\{.*\}/s, text)
      if json_match do
        plan_json = List.first(json_match)
        IO.puts("\n=== Parsed Plan Structure ===\n")
        
        case Jason.decode(plan_json) do
          {:ok, plan} ->
            steps = Map.get(plan, "steps", [])
            IO.puts("Total steps: #{length(steps)}\n")
            
            IO.puts("Plan Steps:")
            Enum.each(Enum.with_index(steps, 1), fn {step, idx} ->
              tool = Map.get(step, "tool")
              desc = Map.get(step, "description", "")
              args = Map.get(step, "args", %{})
              deps = Map.get(step, "dependencies", [])
              
              IO.puts("\n#{idx}. #{tool}")
              IO.puts("   Description: #{desc}")
              
              case tool do
                "reset_scene" ->
                  IO.puts("   Action: Remove all starter objects")
                "set_scene_fps" ->
                  fps = Map.get(args, "fps", 30)
                  IO.puts("   Action: Set FPS to #{fps}")
                "create_cube" ->
                  name = Map.get(args, "name")
                  location = Map.get(args, "location")
                  size = Map.get(args, "size")
                  IO.puts("   Action: Create cube '#{name}'")
                  IO.puts("   Location: #{inspect(location)}")
                  IO.puts("   Size: #{size}")
                "set_keyframe" ->
                  object = Map.get(args, "object")
                  frame = Map.get(args, "frame")
                  value = Map.get(args, "value")
                  IO.puts("   Action: Set keyframe for '#{object}'")
                  IO.puts("   Frame: #{frame}")
                  IO.puts("   Value: #{inspect(value)}")
                _ ->
                  if map_size(args) > 0 do
                    IO.puts("   Args: #{inspect(args)}")
                  end
              end
              
              if length(deps) > 0 do
                IO.puts("   Dependencies: #{inspect(deps)}")
              end
            end)
            
            IO.puts("\n" <> String.duplicate("=", 70))
            IO.puts("Plan Summary:")
            IO.puts("  - #{length(steps)} total steps")
            create_steps = Enum.count(steps, fn s -> Map.get(s, "tool") == "create_cube" end)
            keyframe_steps = Enum.count(steps, fn s -> Map.get(s, "tool") == "set_keyframe" end)
            IO.puts("  - #{create_steps} object creation steps")
            IO.puts("  - #{keyframe_steps} keyframe steps")
            IO.puts("  - Planner used backtracking to order operations correctly")
            
          {:error, decode_error} ->
            IO.puts("Failed to decode plan JSON: #{inspect(decode_error)}")
        end
      end
      
    {:error, reason, _state} ->
      IO.puts("✗ Planning failed: #{reason}\n")
      
      if String.contains?(to_string(reason), "AriaPlanner not available") do
        IO.puts("⚠ aria_planner is not available.")
        IO.puts("   Showing expected plan structure based on domain decomposition:\n")
        
        # Show what the domain would decompose to
        domain = Planning.create_forge_domain_spec()
        methods = Map.get(domain, :methods)
        
        prepare_fn = Map.get(methods, "prepare_scene")
        stacking_fn = Map.get(methods, "stacking_animation")
        
        if prepare_fn && stacking_fn do
          IO.puts("Domain Decomposition:")
          IO.puts("\n1. prepare_scene decomposes to:")
          prepare_tasks = prepare_fn.(%{}, %{"fps" => 30})
          Enum.each(prepare_tasks, fn {task, args} ->
            IO.puts("   - #{task} #{inspect(args)}")
          end)
          
          IO.puts("\n2. stacking_animation decomposes to:")
          stacking_tasks = stacking_fn.(%{}, %{
            "count" => 3,
            "base_location" => [0, 0, 0],
            "spacing" => 2.0,
            "start_frame" => 1,
            "frames_per_object" => 30
          })
          Enum.each(Enum.with_index(stacking_tasks, 1), fn {{task, args}, idx} ->
            IO.puts("   #{idx}. #{task}")
            case task do
              "create_cube" ->
                IO.puts("      Name: #{Map.get(args, "name")}")
                IO.puts("      Location: #{inspect(Map.get(args, "location"))}")
              "set_keyframe" ->
                IO.puts("      Object: #{Map.get(args, "object")}")
                IO.puts("      Frame: #{Map.get(args, "frame")}")
              _ ->
                nil
            end
          end)
          
          IO.puts("\n⚠ When aria_planner is available, it will:")
          IO.puts("   - Use backtracking to ensure objects are created before keyframes")
          IO.puts("   - Order all operations respecting dependencies")
          IO.puts("   - Generate an executable plan")
        end
      end
  end
rescue
  e ->
    IO.puts("Error calling planner: #{inspect(e)}")
    IO.puts("\nTrying direct Planning module call...\n")
    
    # Fallback: try direct call
    temp_dir = System.tmp_dir!()
    case Planning.run_lazy_planning(plan_spec, temp_dir) do
      {:ok, plan_json} ->
        IO.puts("✓ Plan generated directly\n")
        case Jason.decode(plan_json) do
          {:ok, plan} ->
            steps = Map.get(plan, "steps", [])
            IO.puts("Plan has #{length(steps)} steps")
            Enum.each(Enum.take(steps, 10), fn step ->
              IO.puts("  - #{Map.get(step, "tool")}: #{Map.get(step, "description")}")
            end)
          _ ->
            IO.puts("Plan JSON: #{String.slice(plan_json, 0, 500)}")
        end
      {:error, reason} ->
        IO.puts("Planning failed: #{reason}")
    end
end

