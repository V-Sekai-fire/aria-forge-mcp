# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService.Prompts do
  @moduledoc """
  Hard-coded seed prompts containing example plans for common Blender workflows.
  
  These prompts serve as templates and examples that users can reference
  or modify for their own planning tasks.
  """
  
  @doc """
  Get all available seed prompts.
  """
  @spec list_prompts() :: [map()]
  def list_prompts do
    [
      %{
        "name" => "basic_scene_setup",
        "description" => "Basic scene setup: Create a simple scene with a few objects"
      },
      %{
        "name" => "cube_grid_plan",
        "description" => "Create a grid of cubes with dependencies"
      },
      %{
        "name" => "sphere_pattern_plan",
        "description" => "Create spheres in a circular pattern"
      },
      %{
        "name" => "mixed_objects_plan",
        "description" => "Create a mixed scene with cubes and spheres with constraints"
      },
      %{
        "name" => "hierarchical_scene_plan",
        "description" => "Complex hierarchical scene construction plan"
      }
    ]
  end
  
  @doc """
  Get a specific prompt by name.
  """
  @spec get_prompt(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_prompt("basic_scene_setup"), do: {:ok, basic_scene_setup_prompt()}
  def get_prompt("cube_grid_plan"), do: {:ok, cube_grid_plan_prompt()}
  def get_prompt("sphere_pattern_plan"), do: {:ok, sphere_pattern_plan_prompt()}
  def get_prompt("mixed_objects_plan"), do: {:ok, mixed_objects_plan_prompt()}
  def get_prompt("hierarchical_scene_plan"), do: {:ok, hierarchical_scene_plan_prompt()}
  def get_prompt(name), do: {:error, "Unknown prompt: #{name}"}
  
  # Hard-coded plan prompts
  
  defp basic_scene_setup_prompt do
    %{
      "name" => "basic_scene_setup",
      "description" => "Basic scene setup: Create a simple scene with a few objects",
      "arguments" => [],
      "messages" => [
        %{
          "role" => "user",
          "content" => %{
            "type" => "text",
            "text" => """
Use the bpy-mcp planning tools to create a basic scene setup plan.

Plan Specification:
- Initial state: Empty scene
- Goal state: 
  - Create 3 cubes at positions: [0,0,0], [3,0,0], [6,0,0]
  - Create 2 spheres at positions: [0,3,0], [3,3,0]
- Constraints: None

Steps:
1. Call plan_scene_construction with the above specification
2. Review the generated plan
3. Execute the plan using execute_plan

Example plan that should be generated:
{
  "steps": [
    {"tool": "create_cube", "args": {"name": "Cube1", "location": [0,0,0], "size": 2.0}},
    {"tool": "create_cube", "args": {"name": "Cube2", "location": [3,0,0], "size": 2.0}},
    {"tool": "create_cube", "args": {"name": "Cube3", "location": [6,0,0], "size": 2.0}},
    {"tool": "create_sphere", "args": {"name": "Sphere1", "location": [0,3,0], "radius": 1.0}},
    {"tool": "create_sphere", "args": {"name": "Sphere2", "location": [3,3,0], "radius": 1.0}}
  ],
  "total_operations": 5,
  "estimated_complexity": "simple"
}
"""
          }
        }
      ]
    }
  end
  
  defp cube_grid_plan_prompt do
    %{
      "name" => "cube_grid_plan",
      "description" => "Create a grid of cubes with dependencies",
      "arguments" => [],
      "messages" => [
        %{
          "role" => "user",
          "content" => %{
            "type" => "text",
            "text" => """
Plan a 3x3 grid of cubes with dependencies.

Plan Specification:
- Initial state: Empty scene
- Goal state: 9 cubes arranged in a 3x3 grid
  - Grid positions: 
    * Row 1: [0,0,0], [2,0,0], [4,0,0]
    * Row 2: [0,2,0], [2,2,0], [4,2,0]
    * Row 3: [0,4,0], [2,4,0], [4,4,0]
- Constraints:
  - Row 1 must be created before Row 2
  - Row 2 must be created before Row 3
  - Within each row, cubes must be created left-to-right

This plan will use run_lazy planning to schedule operations optimally, respecting dependencies.
Expected plan will have:
- 9 create_cube operations
- Dependencies enforcing row-by-row, left-to-right creation
- Optimal scheduling via run_lazy's lazy refinement algorithm
"""
          }
        }
      ]
    }
  end
  
  defp sphere_pattern_plan_prompt do
    %{
      "name" => "sphere_pattern_plan",
      "description" => "Create spheres in a circular pattern",
      "arguments" => [],
      "messages" => [
        %{
          "role" => "user",
          "content" => %{
            "type" => "text",
            "text" => """
Plan creation of spheres arranged in a circular pattern.

Plan Specification:
- Initial state: Empty scene
- Goal state: 8 spheres arranged in a circle
  - Circle center: [0,0,0]
  - Circle radius: 5
  - 8 spheres evenly spaced around the circle
- Constraints:
  - Each sphere's position depends on angle calculation
  - Spheres can be created in parallel (no dependencies)

This is a simple plan since there are no dependencies - all spheres can be created simultaneously.
The plan will show 8 parallel create_sphere operations.
"""
          }
        }
      ]
    }
  end
  
  defp mixed_objects_plan_prompt do
    %{
      "name" => "mixed_objects_plan",
      "description" => "Create a mixed scene with cubes and spheres with constraints",
      "arguments" => [],
      "messages" => [
        %{
          "role" => "user",
          "content" => %{
            "type" => "text",
            "text" => """
Plan a complex scene with mixed objects and dependencies.

Plan Specification:
- Initial state: Empty scene
- Goal state:
  - 4 cubes: Cube1 at [0,0,0], Cube2 at [3,0,0], Cube3 at [6,0,0], Cube4 at [9,0,0]
  - 3 spheres: Sphere1 at [0,3,0], Sphere2 at [3,3,0], Sphere3 at [6,3,0]
- Constraints:
  - Cube1 must be created before Cube2
  - Cube2 must be created before Cube3
  - Cube3 must be created before Cube4
  - All cubes must be created before any sphere
  - Sphere1 must be created before Sphere2
  - Sphere2 must be created before Sphere3

This plan will demonstrate run_lazy scheduling with dependency resolution:
Cube1 → Cube2 → Cube3 → Cube4 → Sphere1 → Sphere2 → Sphere3
The planner will respect all dependencies and schedule optimally.
"""
          }
        }
      ]
    }
  end
  
  defp hierarchical_scene_plan_prompt do
    %{
      "name" => "hierarchical_scene_plan",
      "description" => "Complex hierarchical scene construction plan",
      "arguments" => [],
      "messages" => [
        %{
          "role" => "user",
          "content" => %{
            "type" => "text",
            "text" => """
Plan a complex hierarchical scene using goal decomposition.

Plan Specification:
- Initial state: Empty scene
- Goal state: High-level description "Create a room scene with furniture"
- Decomposition:
  Level 1: Room structure (floor, walls)
  Level 2: Furniture (table, chairs)
  Level 3: Details (objects on table)
- Constraints:
  - Floor must be created first
  - Walls depend on floor
  - Furniture depends on floor completion
  - Table must be created before objects on table

This plan will use run_lazy goal decomposition:
1. High-level goal: "Create room scene"
2. Decomposed to: Create floor, create walls, create furniture, add details
3. Each subgoal further decomposed into specific operations
4. Final plan: Sequence of create_cube/create_sphere operations

Expected plan structure:
{
  "steps": [
    {"tool": "create_cube", "description": "Create floor"},
    {"tool": "create_cube", "description": "Create wall 1"},
    {"tool": "create_cube", "description": "Create wall 2"},
    {"tool": "create_cube", "description": "Create table"},
    {"tool": "create_cube", "description": "Create object on table"}
  ],
  "planner": "run_lazy",
  "solution_graph": {...}
}
"""
          }
        }
      ]
    }
  end
end

