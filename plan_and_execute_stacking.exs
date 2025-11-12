# Plan and execute stacking animation
alias AriaForge.Tools.Planning

temp_dir = System.tmp_dir!()

IO.puts("=== Planning Stacking Animation ===\n")

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

IO.puts("Generating plan...")
case Planning.run_lazy_planning(plan_spec, temp_dir) do
  {:ok, plan_json} ->
    IO.puts("✓ Plan generated successfully\n")
    
    case Jason.decode(plan_json) do
      {:ok, plan} ->
        steps = Map.get(plan, "steps", [])
        IO.puts("Plan has #{length(steps)} steps:\n")
        
        # Show plan structure
        Enum.each(Enum.with_index(steps, 1), fn {step, idx} ->
          tool = Map.get(step, "tool")
          desc = Map.get(step, "description", "")
          args = Map.get(step, "args", %{})
          
          IO.puts("#{idx}. #{tool}")
          IO.puts("   #{desc}")
          if map_size(args) > 0 and tool != "reset_scene" do
            case tool do
              "create_cube" ->
                IO.puts("   Name: #{Map.get(args, "name")}")
                IO.puts("   Location: #{inspect(Map.get(args, "location"))}")
              "set_keyframe" ->
                IO.puts("   Object: #{Map.get(args, "object")}")
                IO.puts("   Frame: #{Map.get(args, "frame")}")
                IO.puts("   Value: #{inspect(Map.get(args, "value"))}")
              "set_scene_fps" ->
                IO.puts("   FPS: #{Map.get(args, "fps")}")
              _ ->
                nil
            end
          end
          IO.puts("")
        end)
        
        # Execute the plan
        IO.puts("=== Executing Plan ===\n")
        case Planning.execute_plan(plan_json, temp_dir) do
          {:ok, result} ->
            IO.puts("✓ Plan executed successfully!")
            IO.puts("Result: #{result}\n")
          {:error, reason} ->
            IO.puts("✗ Plan execution failed: #{reason}\n")
        end
        
      {:error, decode_error} ->
        IO.puts("Failed to decode plan: #{inspect(decode_error)}")
        IO.puts("\nRaw plan (first 1000 chars):")
        IO.puts(String.slice(plan_json, 0, 1000))
    end
    
  {:error, reason} ->
    if String.contains?(to_string(reason), "AriaPlanner not available") do
      IO.puts("⚠ AriaPlanner not available")
      IO.puts("Showing what the plan would contain:\n")
      
      # Show expected plan structure
      IO.puts("Expected plan steps (based on domain decomposition):")
      expected_steps = [
        {"reset_scene", "Reset scene"},
        {"set_scene_fps", "Set FPS to 30"},
        {"create_cube", "Create StackCube1 at [0, 0, -2.0]"},
        {"create_cube", "Create StackCube2 at [0, 0, -4.0]"},
        {"create_cube", "Create StackCube3 at [0, 0, -6.0]"},
        {"set_keyframe", "Set keyframe for StackCube1 at frame 1"},
        {"set_keyframe", "Set keyframe for StackCube1 at frame 31"},
        {"set_keyframe", "Set keyframe for StackCube2 at frame 31"},
        {"set_keyframe", "Set keyframe for StackCube2 at frame 61"},
        {"set_keyframe", "Set keyframe for StackCube3 at frame 61"},
        {"set_keyframe", "Set keyframe for StackCube3 at frame 91"}
      ]
      
      Enum.each(Enum.with_index(expected_steps, 1), fn {{tool, desc}, idx} ->
        IO.puts("  #{idx}. #{tool}: #{desc}")
      end)
      
      IO.puts("\n⚠ Note: When aria_planner is available, it will:")
      IO.puts("   - Use backtracking to ensure objects are created before keyframes")
      IO.puts("   - Generate this plan automatically")
      IO.puts("   - Execute it through the planning execution system")
    else
      IO.puts("✗ Planning failed: #{reason}")
    end
end
