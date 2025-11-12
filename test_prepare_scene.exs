# Test script to demonstrate prepare_scene planning
alias AriaForge.Tools.Planning

# Create a temporary directory (in real usage, this would be provided)
temp_dir = System.tmp_dir!()

# Create plan spec for prepare_scene
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"prepare_scene", %{"fps" => 30}}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{"execution" => false}
}

IO.puts("Generating plan for prepare_scene...")
case Planning.run_lazy_planning(plan_spec, temp_dir) do
  {:ok, plan_json} ->
    IO.puts("Plan generated successfully:")
    IO.puts(plan_json)
    
    # Decode and show the plan structure
    case Jason.decode(plan_json) do
      {:ok, plan} ->
        IO.puts("\nPlan structure:")
        IO.inspect(plan, pretty: true)
        
        # Execute the plan
        IO.puts("\nExecuting plan...")
        case Planning.execute_plan(plan_json, temp_dir) do
          {:ok, result} ->
            IO.puts("Execution result: #{result}")
          {:error, reason} ->
            IO.puts("Execution failed: #{reason}")
        end
      {:error, _} ->
        IO.puts("Failed to decode plan JSON")
    end
  {:error, reason} ->
    IO.puts("Planning failed: #{reason}")
end

