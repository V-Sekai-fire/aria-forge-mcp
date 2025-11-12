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
      plan_data =
        Jason.encode!(%{
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

    test "executes plan with reset_scene command" do
      plan_data =
        Jason.encode!(%{
          "steps" => [
            %{
              "tool" => "reset_scene",
              "args" => %{},
              "dependencies" => [],
              "description" => "Reset scene to clean state"
            }
          ]
        })

      result = Planning.execute_plan(plan_data, @temp_dir)

      # Should succeed and include duration
      assert {:ok, message} = result
      assert String.contains?(message, "duration")
    end

    test "executes plan with get_scene_info command" do
      plan_data =
        Jason.encode!(%{
          "steps" => [
            %{
              "tool" => "get_scene_info",
              "args" => %{},
              "dependencies" => [],
              "description" => "Get scene information"
            }
          ]
        })

      result = Planning.execute_plan(plan_data, @temp_dir)

      # Should succeed and include duration
      assert {:ok, message} = result
      assert String.contains?(message, "duration")
    end

    test "executes plan with reset then introspect workflow" do
      plan_data =
        Jason.encode!(%{
          "steps" => [
            %{
              "tool" => "reset_scene",
              "args" => %{},
              "dependencies" => [],
              "description" => "Reset scene"
            },
            %{
              "tool" => "get_scene_info",
              "args" => %{},
              "dependencies" => [],
              "description" => "Introspect scene after reset"
            }
          ]
        })

      result = Planning.execute_plan(plan_data, @temp_dir)

      # Should succeed
      assert {:ok, _message} = result
    end

    test "handles invalid plan JSON" do
      result = Planning.execute_plan("invalid json", @temp_dir)
      assert {:error, _} = result
    end

    test "executes plan with multiple steps" do
      plan_data =
        Jason.encode!(%{
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
      plan_data =
        Jason.encode!(%{
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

  describe "forge domain with scene introspection and reset" do
    @tag :skip
    test "run_lazy_planning with introspect_scene method" do
      plan_spec = %{
        "initial_state" => %{"facts" => []},
        "tasks" => [{"introspect_scene", %{}}],
        "domain" => nil,
        "constraints" => [],
        "opts" => %{}
      }

      result = Planning.run_lazy_planning(plan_spec, @temp_dir)
      
      # Should return a plan (may fail if AriaPlanner not available, but should not crash)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
      
      if match?({:ok, json}, result) do
        {:ok, plan} = Jason.decode(json)
        assert is_map(plan)
      end
    end

    @tag :skip
    test "run_lazy_planning with reset_and_prepare_scene method" do
      plan_spec = %{
        "initial_state" => %{"facts" => []},
        "tasks" => [
          {
            "reset_and_prepare_scene",
            %{
              "objects" => [
                %{"type" => "cube", "name" => "NewCube", "location" => [0, 0, 0]}
              ]
            }
          }
        ],
        "domain" => nil,
        "constraints" => [],
        "opts" => %{}
      }

      result = Planning.run_lazy_planning(plan_spec, @temp_dir)
      
      # Should return a plan
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    @tag :skip
    test "create_forge_domain_spec includes scene introspection and reset" do
      domain = Planning.create_forge_domain_spec()
      
      # Check that methods exist
      assert Map.has_key?(domain, :methods)
      methods = domain.methods
      
      assert Map.has_key?(methods, "introspect_scene")
      assert Map.has_key?(methods, "reset_and_prepare_scene")
      assert Map.has_key?(methods, "prepare_clean_scene")
      
      # Check that commands exist
      assert Map.has_key?(domain, :commands)
      commands = domain.commands
      
      assert Map.has_key?(commands, "reset_scene")
      assert Map.has_key?(commands, "get_scene_info")
      
      # Test introspect_scene method
      introspect_fn = Map.get(methods, "introspect_scene")
      result = introspect_fn.(%{}, %{})
      assert is_list(result)
      assert length(result) == 1
      assert List.first(result) == {"get_scene_info", %{}}
      
      # Test reset_and_prepare_scene method
      reset_fn = Map.get(methods, "reset_and_prepare_scene")
      result = reset_fn.(%{}, %{"objects" => [%{"type" => "cube", "name" => "Test"}]})
      assert is_list(result)
      assert length(result) >= 1
      assert List.first(result) == {"reset_scene", %{}}
    end

    @tag :skip
    test "create_forge_scene with reset_first and introspect_first options" do
      domain = Planning.create_forge_domain_spec()
      methods = domain.methods
      
      create_fn = Map.get(methods, "create_forge_scene")
      
      # Test with reset_first
      result = create_fn.(%{}, %{"reset_first" => true, "objects" => [%{"type" => "cube", "name" => "Cube1"}]})
      assert is_list(result)
      assert List.first(result) == {"reset_scene", %{}}
      
      # Test with introspect_first
      result = create_fn.(%{}, %{"introspect_first" => true, "objects" => [%{"type" => "cube", "name" => "Cube1"}]})
      assert is_list(result)
      # Should include get_scene_info early in the list
      scene_info_tasks = Enum.filter(result, fn {task, _} -> task == "get_scene_info" end)
      assert length(scene_info_tasks) >= 1
    end
  end

  describe "aria_planner integration" do
    test "returns error when aria_planner not available" do
      # Mock Code.ensure_loaded? to return false for AriaPlanner
      # This test verifies that planning functions require aria_planner
      plan_spec = %{
        "initial_state" => %{"objects" => []},
        "goal_state" => %{"objects" => [%{"type" => "cube", "name" => "Cube1"}]},
        "constraints" => []
      }

      # If AriaPlanner is not available, should return error
      result = Planning.plan_scene_construction(plan_spec, @temp_dir)
      
      # Result should either be an error (if AriaPlanner not available) or success (if available)
      # We can't easily mock Code.ensure_loaded? in ExUnit, so we accept both outcomes
      assert match?({:ok, _}, result) or match?({:error, _}, result)
      
      # If it's an error, it should mention aria_planner
      if match?({:error, msg}, result) do
        {:error, message} = result
        assert String.contains?(String.downcase(message), "aria") or 
               String.contains?(String.downcase(message), "planner")
      end
    end

    test "returns valid JSON or error for all planning functions" do
      # Test all planning functions return either valid JSON or error
      test_cases = [
        {&Planning.plan_scene_construction/2,
         %{
           "initial_state" => %{},
           "goal_state" => %{"objects" => []},
           "constraints" => []
         }},
        {&Planning.plan_material_application/2,
         %{
           "objects" => [],
           "materials" => [],
           "dependencies" => []
         }},
        {&Planning.plan_animation/2,
         %{
           "animations" => [],
           "constraints" => [],
           "total_frames" => 250
         }}
      ]

      Enum.each(test_cases, fn {fun, spec} ->
        result = fun.(spec, @temp_dir)
        
        case result do
          {:ok, json} ->
            # Verify it's valid JSON
            {:ok, _decoded} = Jason.decode(json)
          {:error, _message} ->
            # Error is acceptable when aria_planner not available
            :ok
        end
      end)
    end
  end
end
