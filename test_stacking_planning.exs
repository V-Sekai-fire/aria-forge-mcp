# Test stacking animation planning using aria_planner via NativeService
Mix.install([])

# Start the application
Application.ensure_all_started(:aria_forge)

alias AriaForge.NativeService

IO.puts("=== Planning Stacking Animation with aria_planner ===\n")

# Initialize server state
state = %{}

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

args = %{
  "plan_spec" => plan_spec
}

IO.puts("Calling run_lazy planner...\n")
result = NativeService.handle_tool_call("run_lazy", args, state)

case result do
  {:ok, %{content: [%{"text" => text}]}, new_state} ->
    IO.puts("✓ Planning successful!\n")
    IO.puts("Plan result:")
    IO.puts(String.duplicate("=", 60))
    IO.puts(text)
    IO.puts(String.duplicate("=", 60))
    
    # Try to extract and execute the plan
    IO.puts("\n=== Extracting plan for execution ===\n")
    
    # Extract JSON from the text
    json_match = Regex.run(~r/\{.*\}/s, text)
    if json_match do
      plan_json = List.first(json_match)
      
      IO.puts("Found plan JSON, executing...\n")
      
      # Execute the plan
      execute_args = %{
        "plan_data" => plan_json
      }
      
      exec_result = NativeService.handle_tool_call("execute_plan", execute_args, new_state)
      
      case exec_result do
        {:ok, %{content: [%{"text" => exec_text}]}, _final_state} ->
          IO.puts("✓ Plan execution result:")
          IO.puts(exec_text)
        {:error, reason, _state} ->
          IO.puts("✗ Execution failed: #{reason}")
      end
    else
      IO.puts("⚠ Could not extract plan JSON from result")
      IO.puts("Plan text (first 500 chars):")
      IO.puts(String.slice(text, 0, 500))
    end
    
  {:error, reason, _state} ->
    IO.puts("✗ Planning failed: #{reason}")
    if String.contains?(to_string(reason), "AriaPlanner not available") do
      IO.puts("\n⚠ aria_planner is not available.")
      IO.puts("   Please ensure aria_planner is installed and available.")
    end
end

