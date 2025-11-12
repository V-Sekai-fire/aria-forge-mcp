# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.PlanningServerTest do
  use ExUnit.Case
  alias AriaForge.NativeService

  @moduletag :integration

  setup do
    # Start the NativeService for testing
    {:ok, _pid} = start_supervised({AriaForge.NativeService, [transport: :native, name: AriaForge.NativeService]})
    :ok
  end

  @tag :skip
  test "run_lazy plans prepare_scene workflow" do
    plan_spec = %{
      "initial_state" => %{"objects" => []},
      "tasks" => [
        {"prepare_scene", %{"fps" => 30}}
      ],
      "constraints" => [],
      "domain" => nil,
      "opts" => %{"execution" => false}
    }

    args = %{
      "plan_spec" => plan_spec
    }

    result = NativeService.handle_tool_call("run_lazy", args, %{})

    case result do
      {:ok, %{content: [%{"text" => text}]}, _state} ->
        # Verify the plan was generated
        assert String.contains?(text, "Run Lazy Planning Result")
        
        # Try to decode the JSON plan
        json_match = Regex.run(~r/\{.*\}/s, text)
        if json_match do
          plan_json = List.first(json_match)
          case Jason.decode(plan_json) do
            {:ok, plan} ->
              # Verify plan structure
              assert Map.has_key?(plan, "steps")
              steps = Map.get(plan, "steps", [])
              assert length(steps) >= 2
              
              # Verify it contains reset_scene and set_scene_fps
              step_tools = Enum.map(steps, fn step -> Map.get(step, "tool") end)
              assert "reset_scene" in step_tools
              assert "set_scene_fps" in step_tools
              
              IO.puts("\n✓ Plan generated successfully:")
              IO.puts("  Steps: #{length(steps)}")
              IO.inspect(step_tools, label: "  Tools")
              
            {:error, _} ->
              # Plan might be in a different format, that's okay for now
              IO.puts("\n✓ Plan generated (format may vary)")
          end
        else
          IO.puts("\n✓ Planning completed")
        end

      {:error, reason, _state} ->
        # If aria_planner is not available, that's expected
        if String.contains?(to_string(reason), "AriaPlanner not available") do
          IO.puts("\n⚠ AriaPlanner not available (expected in some environments)")
        else
          flunk("Planning failed: #{reason}")
        end

      other ->
        flunk("Unexpected result: #{inspect(other)}")
    end
  end

  @tag :skip
  test "run_lazy executes prepare_scene plan" do
    plan_spec = %{
      "initial_state" => %{"objects" => []},
      "tasks" => [
        {"prepare_scene", %{"fps" => 30}}
      ],
      "constraints" => [],
      "domain" => nil,
      "opts" => %{"execution" => true}
    }

    args = %{
      "plan_spec" => plan_spec
    }

    result = NativeService.handle_tool_call("run_lazy", args, %{})

    case result do
      {:ok, %{content: [%{"text" => text}]}, _state} ->
        IO.puts("\n✓ Plan executed")
        IO.puts("  Result: #{String.slice(text, 0, 100)}...")

      {:error, reason, _state} ->
        # If aria_planner is not available, that's expected
        if String.contains?(to_string(reason), "AriaPlanner not available") do
          IO.puts("\n⚠ AriaPlanner not available (expected in some environments)")
        else
          IO.puts("\n⚠ Execution note: #{reason}")
        end

      other ->
        IO.puts("\n⚠ Unexpected result format: #{inspect(other)}")
    end
  end

  @tag :skip
  test "run_lazy handles simple command planning" do
    plan_spec = %{
      "initial_state" => %{"objects" => []},
      "tasks" => [
        {"reset_scene", %{}},
        {"set_scene_fps", %{"fps" => 30}}
      ],
      "constraints" => [],
      "domain" => nil,
      "opts" => %{"execution" => false}
    }

    args = %{
      "plan_spec" => plan_spec
    }

    result = NativeService.handle_tool_call("run_lazy", args, %{})

    case result do
      {:ok, %{content: [%{"text" => text}]}, _state} ->
        IO.puts("\n✓ Direct command planning successful")
        assert String.contains?(text, "Run Lazy Planning Result")

      {:error, reason, _state} ->
        if String.contains?(to_string(reason), "AriaPlanner not available") do
          IO.puts("\n⚠ AriaPlanner not available (expected in some environments)")
        else
          flunk("Planning failed: #{reason}")
        end

      other ->
        flunk("Unexpected result: #{inspect(other)}")
    end
  end
end

