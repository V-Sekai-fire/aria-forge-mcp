# Test script to demonstrate planning with scene introspection
alias AriaForge.Tools.Planning

# Create a temporary directory
temp_dir = System.tmp_dir!()

IO.puts("=== Testing prepare_scene with introspection ===\n")

# Test 1: prepare_scene with introspection after
IO.puts("Test 1: prepare_scene with introspection_after")
plan_spec1 = %{
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

case Planning.run_lazy_planning(plan_spec1, temp_dir) do
  {:ok, plan_json} ->
    IO.puts("✓ Plan generated")
    case Jason.decode(plan_json) do
      {:ok, plan} ->
        steps = Map.get(plan, "steps", [])
        IO.puts("  Steps: #{length(steps)}")
        Enum.each(steps, fn step ->
          tool = Map.get(step, "tool")
          desc = Map.get(step, "description", "")
          IO.puts("    - #{tool}: #{desc}")
        end)
        
        # Verify introspection is included
        step_tools = Enum.map(steps, fn s -> Map.get(s, "tool") end)
        if "get_scene_info" in step_tools do
          IO.puts("  ✓ Scene introspection included in plan")
        else
          IO.puts("  ⚠ Scene introspection not found")
        end
      {:error, _} ->
        IO.puts("  Plan JSON: #{String.slice(plan_json, 0, 200)}...")
    end
  {:error, reason} ->
    if String.contains?(to_string(reason), "AriaPlanner not available") do
      IO.puts("  ⚠ AriaPlanner not available: #{reason}")
    else
      IO.puts("  ✗ Planning failed: #{reason}")
    end
end

IO.puts("\n=== Test 2: Direct introspection_scene method ===\n")

# Test 2: Direct introspection_scene method
plan_spec2 = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"introspect_scene", %{}}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{"execution" => false}
}

case Planning.run_lazy_planning(plan_spec2, temp_dir) do
  {:ok, plan_json} ->
    IO.puts("✓ Introspection plan generated")
    case Jason.decode(plan_json) do
      {:ok, plan} ->
        steps = Map.get(plan, "steps", [])
        IO.puts("  Steps: #{length(steps)}")
        Enum.each(steps, fn step ->
          tool = Map.get(step, "tool")
          desc = Map.get(step, "description", "")
          IO.puts("    - #{tool}: #{desc}")
        end)
      {:error, _} ->
        IO.puts("  Plan JSON: #{String.slice(plan_json, 0, 200)}...")
    end
  {:error, reason} ->
    if String.contains?(to_string(reason), "AriaPlanner not available") do
      IO.puts("  ⚠ AriaPlanner not available: #{reason}")
    else
      IO.puts("  ✗ Planning failed: #{reason}")
    end
end

IO.puts("\n=== Test 3: prepare_scene with introspection before and after ===\n")

# Test 3: prepare_scene with both introspection options
plan_spec3 = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"prepare_scene", %{
      "fps" => 30,
      "introspect_before" => true,
      "introspect_after" => true
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{"execution" => false}
}

case Planning.run_lazy_planning(plan_spec3, temp_dir) do
  {:ok, plan_json} ->
    IO.puts("✓ Plan with before/after introspection generated")
    case Jason.decode(plan_json) do
      {:ok, plan} ->
        steps = Map.get(plan, "steps", [])
        IO.puts("  Steps: #{length(steps)}")
        Enum.each(steps, fn step ->
          tool = Map.get(step, "tool")
          desc = Map.get(step, "description", "")
          IO.puts("    - #{tool}: #{desc}")
        end)
        
        step_tools = Enum.map(steps, fn s -> Map.get(s, "tool") end)
        introspect_count = Enum.count(step_tools, fn t -> t == "get_scene_info" end)
        IO.puts("  ✓ Scene introspection appears #{introspect_count} time(s)")
      {:error, _} ->
        IO.puts("  Plan JSON: #{String.slice(plan_json, 0, 200)}...")
    end
  {:error, reason} ->
    if String.contains?(to_string(reason), "AriaPlanner not available") do
      IO.puts("  ⚠ AriaPlanner not available: #{reason}")
    else
      IO.puts("  ✗ Planning failed: #{reason}")
    end
end

IO.puts("\n=== Done ===")

