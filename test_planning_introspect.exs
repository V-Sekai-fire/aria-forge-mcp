# Test planning with introspection via the planning system
alias AriaForge.Tools.Planning

temp_dir = System.tmp_dir!()

IO.puts("=== Planning prepare_scene with introspection ===\n")

# Create plan spec with introspection
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"prepare_scene", %{
      "fps" => 30,
      "introspect_after" => true
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{"execution" => false}
}

IO.puts("Generating plan...")
case Planning.run_lazy_planning(plan_spec, temp_dir) do
  {:ok, plan_json} ->
    IO.puts("✓ Plan generated\n")
    
    case Jason.decode(plan_json) do
      {:ok, plan} ->
        steps = Map.get(plan, "steps", [])
        IO.puts("Plan has #{length(steps)} steps:\n")
        
        Enum.each(Enum.with_index(steps, 1), fn {step, idx} ->
          tool = Map.get(step, "tool")
          desc = Map.get(step, "description", "")
          args = Map.get(step, "args", %{})
          IO.puts("#{idx}. #{tool}")
          IO.puts("   Description: #{desc}")
          if map_size(args) > 0 do
            IO.puts("   Args: #{inspect(args)}")
          end
          IO.puts("")
        end)
        
        # Now execute the plan
        IO.puts("=== Executing plan ===\n")
        case Planning.execute_plan(plan_json, temp_dir) do
          {:ok, result} ->
            IO.puts("✓ Plan executed successfully")
            IO.puts("Result: #{result}")
          {:error, reason} ->
            IO.puts("✗ Plan execution failed: #{reason}")
        end
        
      {:error, decode_error} ->
        IO.puts("Failed to decode plan JSON: #{inspect(decode_error)}")
        IO.puts("Raw plan (first 500 chars):")
        IO.puts(String.slice(plan_json, 0, 500))
    end
    
  {:error, reason} ->
    if String.contains?(to_string(reason), "AriaPlanner not available") do
      IO.puts("⚠ AriaPlanner not available")
      IO.puts("This is expected if aria_planner is not installed.")
      IO.puts("\nHowever, we can still test the domain decomposition manually:")
      IO.puts("\nThe prepare_scene method would decompose into:")
      IO.puts("  1. reset_scene")
      IO.puts("  2. set_scene_fps (fps: 30)")
      IO.puts("  3. introspect_scene (because introspect_after: true)")
      IO.puts("\nAnd introspect_scene would decompose to:")
      IO.puts("  1. get_scene_info")
    else
      IO.puts("✗ Planning failed: #{reason}")
    end
end

