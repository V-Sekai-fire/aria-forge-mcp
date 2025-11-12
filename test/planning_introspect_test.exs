# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.PlanningIntrospectTest do
  use ExUnit.Case
  alias AriaForge.Tools.Planning

  @moduletag :integration

  test "prepare_scene domain method decomposes with introspection" do
    # Test that prepare_scene method correctly decomposes when introspection is requested
    domain = Planning.create_forge_domain_spec()
    methods = Map.get(domain, :methods)
    
    # Get the prepare_scene method
    prepare_scene_fn = Map.get(methods, "prepare_scene")
    assert prepare_scene_fn != nil, "prepare_scene method should exist"
    
    # Test decomposition with introspection_after
    goal = %{
      "fps" => 30,
      "introspect_after" => true
    }
    
    tasks = prepare_scene_fn.(%{}, goal)
    
    # Verify the decomposition
    assert is_list(tasks), "prepare_scene should return a list of tasks"
    assert length(tasks) >= 3, "Should have at least reset_scene, set_scene_fps, and introspect_scene"
    
    # Check task order
    task_names = Enum.map(tasks, fn {name, _args} -> name end)
    
    # Should start with reset_scene
    assert List.first(task_names) == "reset_scene", "Should start with reset_scene"
    
    # Should have set_scene_fps
    assert "set_scene_fps" in task_names, "Should include set_scene_fps"
    
    # Should have introspect_scene (which decomposes to get_scene_info)
    assert "introspect_scene" in task_names, "Should include introspect_scene when introspect_after is true"
    
    IO.puts("\n✓ prepare_scene decomposition verified:")
    Enum.each(Enum.with_index(tasks, 1), fn {{task_name, task_args}, idx} ->
      IO.puts("  #{idx}. #{task_name} #{inspect(task_args)}")
    end)
  end

  test "introspect_scene method decomposes to get_scene_info" do
    domain = Planning.create_forge_domain_spec()
    methods = Map.get(domain, :methods)
    
    # Get the introspect_scene method
    introspect_scene_fn = Map.get(methods, "introspect_scene")
    assert introspect_scene_fn != nil, "introspect_scene method should exist"
    
    # Test decomposition
    tasks = introspect_scene_fn.(%{}, %{})
    
    # Should decompose to get_scene_info
    assert is_list(tasks), "introspect_scene should return a list of tasks"
    assert length(tasks) == 1, "introspect_scene should decompose to one task"
    assert List.first(tasks) == {"get_scene_info", %{}}, "Should decompose to get_scene_info"
    
    IO.puts("\n✓ introspect_scene decomposes to get_scene_info")
  end

  test "prepare_scene with introspection_before includes introspection first" do
    domain = Planning.create_forge_domain_spec()
    methods = Map.get(domain, :methods)
    prepare_scene_fn = Map.get(methods, "prepare_scene")
    
    goal = %{
      "fps" => 30,
      "introspect_before" => true
    }
    
    tasks = prepare_scene_fn.(%{}, goal)
    task_names = Enum.map(tasks, fn {name, _args} -> name end)
    
    # Should start with introspect_scene
    assert List.first(task_names) == "introspect_scene", "Should start with introspect_scene when introspect_before is true"
    
    IO.puts("\n✓ prepare_scene with introspection_before:")
    Enum.each(Enum.with_index(tasks, 1), fn {{task_name, task_args}, idx} ->
      IO.puts("  #{idx}. #{task_name} #{inspect(task_args)}")
    end)
  end

  test "prepare_scene with both introspection options" do
    domain = Planning.create_forge_domain_spec()
    methods = Map.get(domain, :methods)
    prepare_scene_fn = Map.get(methods, "prepare_scene")
    
    goal = %{
      "fps" => 30,
      "introspect_before" => true,
      "introspect_after" => true
    }
    
    tasks = prepare_scene_fn.(%{}, goal)
    task_names = Enum.map(tasks, fn {name, _args} -> name end)
    
    # Should have introspection at both ends
    assert List.first(task_names) == "introspect_scene", "Should start with introspect_scene"
    assert List.last(task_names) == "introspect_scene", "Should end with introspect_scene"
    
    # Count introspect_scene occurrences
    introspect_count = Enum.count(task_names, fn name -> name == "introspect_scene" end)
    assert introspect_count == 2, "Should have introspection twice (before and after)"
    
    IO.puts("\n✓ prepare_scene with both introspection options:")
    Enum.each(Enum.with_index(tasks, 1), fn {{task_name, task_args}, idx} ->
      IO.puts("  #{idx}. #{task_name} #{inspect(task_args)}")
    end)
  end

  @tag :skip
  test "run_lazy planning with introspection executes correctly" do
    # This test requires aria_planner to be available
    temp_dir = System.tmp_dir!()
    
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
    
    case Planning.run_lazy_planning(plan_spec, temp_dir) do
      {:ok, plan_json} ->
        case Jason.decode(plan_json) do
          {:ok, plan} ->
            steps = Map.get(plan, "steps", [])
            step_tools = Enum.map(steps, fn step -> Map.get(step, "tool") end)
            
            # Verify plan includes introspection
            assert "get_scene_info" in step_tools, "Plan should include get_scene_info for introspection"
            
            IO.puts("\n✓ Plan generated with introspection:")
            Enum.each(steps, fn step ->
              IO.puts("  - #{Map.get(step, "tool")}: #{Map.get(step, "description")}")
            end)
            
          {:error, _} ->
            flunk("Failed to decode plan JSON")
        end
        
      {:error, reason} ->
        if String.contains?(to_string(reason), "AriaPlanner not available") do
          IO.puts("\n⚠ AriaPlanner not available (skipping execution test)")
        else
          flunk("Planning failed: #{reason}")
        end
    end
  end
end

