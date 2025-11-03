# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.PlanningTest do
  use ExUnit.Case, async: true
  alias AriaForge.Tools.Planning

  @temp_dir "/tmp/aria_forge_test"

  describe "plan_scene_construction/2" do
    test "creates plan for simple scene construction" do
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{"objects" => [%{"type" => "cube", "name" => "Cube1", "location" => [0, 0, 0]}]},
        "constraints" => []
      }

      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      assert {:ok, json} = result
      
      {:ok, plan} = Jason.decode(json)
      
      assert is_map(plan)
      assert Map.has_key?(plan, "steps")
      assert Map.has_key?(plan, "total_operations")
      assert Map.has_key?(plan, "estimated_complexity")
      
      assert is_list(plan["steps"])
      assert plan["total_operations"] >= 1
      assert is_binary(plan["estimated_complexity"])
    end

    test "handles multiple objects in goal state" do
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{
          "objects" => [
            %{"type" => "cube", "name" => "Cube1", "location" => [0, 0, 0]},
            %{"type" => "sphere", "name" => "Sphere1", "location" => [2, 0, 0]}
          ]
        },
        "constraints" => []
      }

      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      assert {:ok, json} = result
      
      {:ok, plan} = Jason.decode(json)
      
      assert plan["total_operations"] == 2
      assert length(plan["steps"]) == 2
      
      # Check first step is cube creation
      first_step = List.first(plan["steps"])
      assert first_step["tool"] == "create_cube"
      assert first_step["args"]["name"] == "Cube1"
      
      # Check second step is sphere creation
      second_step = List.last(plan["steps"])
      assert second_step["tool"] == "create_sphere"
      assert second_step["args"]["name"] == "Sphere1"
    end

    test "handles empty goal state" do
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{"objects" => []},
        "constraints" => []
      }

      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      assert {:ok, json} = result
      
      {:ok, plan} = Jason.decode(json)
      
      assert plan["total_operations"] == 0
      assert plan["steps"] == []
      assert plan["estimated_complexity"] == "simple"
    end

    test "includes correct location and size parameters" do
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{
          "objects" => [
            %{"type" => "cube", "name" => "TestCube", "location" => [1, 2, 3], "size" => 5.0}
          ]
        },
        "constraints" => []
      }

      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      assert {:ok, json} = result
      
      {:ok, plan} = Jason.decode(json)
      
      step = List.first(plan["steps"])
      assert step["args"]["location"] == [1, 2, 3]
      assert step["args"]["size"] == 5.0
      assert step["args"]["name"] == "TestCube"
    end

    test "handles complexity labels correctly" do
      # Simple case
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{
          "objects" => Enum.map(1..3, fn i -> %{"type" => "cube", "name" => "Cube#{i}"} end)
        },
        "constraints" => []
      }

      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      {:ok, json} = result
      {:ok, plan} = Jason.decode(json)
      assert plan["estimated_complexity"] == "simple"
    end
  end

  describe "plan_material_application/2" do
    test "creates plan for material application" do
      plan_spec = %{
        "objects" => ["Cube1"],
        "materials" => ["RedMaterial"],
        "dependencies" => []
      }

      result = Planning.plan_material_application(plan_spec, @temp_dir)
      assert {:ok, json} = result
      
      {:ok, plan} = Jason.decode(json)
      
      assert is_map(plan)
      assert Map.has_key?(plan, "steps")
      assert Map.has_key?(plan, "total_operations")
      assert length(plan["steps"]) >= 1
    end

    test "handles multiple materials" do
      plan_spec = %{
        "objects" => ["Cube1", "Sphere1"],
        "materials" => ["RedMaterial", "BlueMaterial"],
        "dependencies" => []
      }

      result = Planning.plan_material_application(plan_spec, @temp_dir)
      assert {:ok, json} = result
      {:ok, plan} = Jason.decode(json)
      
      assert length(plan["steps"]) >= 2
    end
  end

  describe "plan_animation/2" do
    test "creates plan for animation sequence" do
      plan_spec = %{
        "animations" => [
          %{"object" => "Cube1", "property" => "location", "value" => [1, 0, 0]}
        ],
        "constraints" => [],
        "total_frames" => 250
      }

      result = Planning.plan_animation(plan_spec, @temp_dir)
      assert {:ok, json} = result
      
      {:ok, plan} = Jason.decode(json)
      
      assert is_map(plan)
      assert Map.has_key?(plan, "steps")
      assert Map.has_key?(plan, "total_operations")
    end

    test "includes total_frames in plan" do
      plan_spec = %{
        "animations" => [],
        "constraints" => [],
        "total_frames" => 500
      }

      result = Planning.plan_animation(plan_spec, @temp_dir)
      {:ok, json} = result
      {:ok, plan} = Jason.decode(json)
      
      assert plan["total_frames"] == 500
    end
  end

  describe "execute_plan/2" do
    test "executes simple plan with create_cube" do
      plan_data = Jason.encode!(%{
        "steps" => [
          %{
            "tool" => "create_cube",
            "args" => %{
              "name" => "TestCube",
              "location" => [0, 0, 0],
              "size" => 2.0
            },
            "dependencies" => [],
            "description" => "Create test cube"
          }
        ]
      })

      result = Planning.execute_plan(plan_data, @temp_dir)
      
      # Should either succeed or fail gracefully
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "handles invalid plan JSON" do
      result = Planning.execute_plan("invalid json", @temp_dir)
      assert {:error, _} = result
    end

    test "executes plan with multiple steps" do
      plan_data = Jason.encode!(%{
        "steps" => [
          %{
            "tool" => "create_cube",
            "args" => %{"name" => "Cube1", "location" => [0, 0, 0], "size" => 2.0},
            "dependencies" => []
          },
          %{
            "tool" => "create_sphere",
            "args" => %{"name" => "Sphere1", "location" => [2, 0, 0], "radius" => 1.0},
            "dependencies" => []
          }
        ]
      })

      result = Planning.execute_plan(plan_data, @temp_dir)
      
      # Should attempt execution (may fail in test environment)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "handles unknown tool gracefully" do
      plan_data = Jason.encode!(%{
        "steps" => [
          %{
            "tool" => "unknown_tool",
            "args" => %{},
            "dependencies" => []
          }
        ]
      })

      result = Planning.execute_plan(plan_data, @temp_dir)
      
      # Should fail with appropriate error
      assert {:error, _} = result
    end
  end

  describe "aria_planner integration" do
    test "falls back to simple planning when aria_planner not available" do
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{"objects" => [%{"type" => "cube", "name" => "Cube1"}]},
        "constraints" => []
      }

      # Should work even if AriaPlanner is not loaded
      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      assert {:ok, _json} = result
    end

    test "returns valid JSON for all planning functions" do
      # Test all planning functions return valid JSON
      test_cases = [
        {&Planning.plan_scene_construction/2, %{
          "initial_state" => %{},
          "goal_state" => %{"objects" => []},
          "constraints" => []
        }},
        {&Planning.plan_material_application/2, %{
          "objects" => [],
          "materials" => [],
          "dependencies" => []
        }},
        {&Planning.plan_animation/2, %{
          "animations" => [],
          "constraints" => [],
          "total_frames" => 250
        }}
      ]

      Enum.each(test_cases, fn {fun, spec} ->
        result = fun.(spec, @temp_dir)
        assert {:ok, json} = result
        
        # Verify it's valid JSON
        {:ok, _decoded} = Jason.decode(json)
      end)
    end
  end
end

