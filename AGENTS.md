# AI Agent Guide: Using AriaForge Planning System

This guide explains how AI agents should interact with the AriaForge planning system to generate and execute complex 3D scene construction workflows.

## Overview

The AriaForge planning system uses the `aria_planner` library to generate ordered sequences of commands that respect dependencies, temporal constraints, and goal hierarchies. **Planning requires `aria_planner` to be installed and available** - there are no fallback planning mechanisms.

## Key Concepts

### Planning Functions

The planning system provides several functions for different planning scenarios:

1. **`run_lazy_planning/2`** - Generic planning function for any scenario
2. **`plan_scene_construction/2`** - Plans scene construction workflows
3. **`plan_material_application/2`** - Plans material application sequences
4. **`plan_animation/2`** - Plans animation sequences with temporal constraints
5. **`execute_plan/2`** - Executes a generated plan

### Domain Specifications

Domain specifications define:
- **Methods**: Goal decomposition functions that break high-level goals into subgoals
- **Commands**: Primitive operations that can be executed directly
- **Initial Tasks**: Tasks that should be included at the start of planning

Two domain specifications are available:
- **`create_forge_domain_spec()`** - Comprehensive domain for all forge operations (default)
- **`create_scene_domain_spec()`** - Focused domain for scene construction

## Requirements

### Required: aria_planner

**All planning functions require `aria_planner` to be available.** If `aria_planner` is not installed or cannot be loaded, planning functions will return an error:

```elixir
{:error, "AriaPlanner not available. Planning requires aria_planner to be installed and available."}
```

**Important**: There are no fallback planning mechanisms. If `aria_planner` is unavailable, planning will fail.

## Using run_lazy_planning

The `run_lazy_planning/2` function is the primary interface for all planning scenarios. It handles:
- Goal decomposition (hierarchical planning)
- Dependency resolution (via backtracking in aria_planner)
- Temporal scheduling (via aria_planner's temporal STN)
- Optimal ordering (via lazy refinement)

### Function Signature

```elixir
@spec run_lazy_planning(map(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
```

### Parameters

The `plan_spec` map should contain:

- **`initial_state`** (map, required): Initial state of the scene/planning problem
  - Example: `%{"objects" => [], "facts" => []}`
  
- **`tasks`** (list, required): List of tasks to accomplish
  - Tasks can be:
    - Tuples: `{"task_name", %{"arg" => "value"}}`
    - Strings: `"task_name"` (no arguments)
    - Maps: `%{"task" => "task_name", "args" => %{}}`
  
- **`constraints`** (list, optional): Constraints on the plan
  - Dependencies: `%{"type" => "dependency", "from" => "task1", "to" => "task2"}`
  - Temporal: `%{"type" => "temporal", "total_frames" => 250}`
  
- **`domain`** (map, optional): Custom domain specification
  - If `nil`, uses default `create_forge_domain_spec()`
  - Can provide custom methods and commands
  
- **`opts`** (map, optional): Planning options
  - `"execution"` (boolean): Whether to execute the plan immediately (default: `false`)

### Example: Basic Scene Construction

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"create_forge_scene", %{
      "objects" => [
        %{"type" => "cube", "name" => "Cube1", "location" => [0, 0, 0]},
        %{"type" => "sphere", "name" => "Sphere1", "location" => [2, 0, 0]}
      ]
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{}
}

result = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
```

### Example: With Scene Reset and Introspection

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"create_forge_scene", %{
      "reset_first" => true,
      "introspect_first" => true,
      "objects" => [
        %{"type" => "cube", "name" => "NewCube", "location" => [0, 0, 0]}
      ],
      "materials" => [
        %{"name" => "RedMaterial", "color" => [1.0, 0.0, 0.0, 1.0]}
      ]
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{}
}

result = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
```

### Example: Custom Domain

```elixir
custom_domain = %{
  methods: %{
    "my_custom_method" => fn _state, goal ->
      [{"create_cube", goal}]
    end
  },
  commands: %{
    "create_cube" => fn state, args -> {:ok, state, "PT1S"} end
  },
  initial_tasks: []
}

plan_spec = %{
  "initial_state" => %{},
  "tasks" => [{"my_custom_method", %{"name" => "TestCube"}}],
  "constraints" => [],
  "domain" => custom_domain,
  "opts" => %{}
}

result = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
```

## Using Specialized Planning Functions

### plan_scene_construction/2

Plans scene construction workflows. Converts goal states into tasks and uses `run_lazy_planning`.

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "goal_state" => %{
    "objects" => [
      %{"type" => "cube", "name" => "Cube1", "location" => [0, 0, 0]}
    ]
  },
  "constraints" => []
}

result = AriaForge.Tools.Planning.plan_scene_construction(plan_spec, temp_dir)
```

### plan_material_application/2

Plans material application sequences with dependency handling.

```elixir
plan_spec = %{
  "objects" => ["Cube1", "Sphere1"],
  "materials" => [
    %{"name" => "RedMaterial", "color" => [1.0, 0.0, 0.0, 1.0]},
    %{"name" => "BlueMaterial", "color" => [0.0, 0.0, 1.0, 1.0]}
  ],
  "dependencies" => [
    %{"type" => "dependency", "from" => "RedMaterial", "to" => "BlueMaterial"}
  ]
}

result = AriaForge.Tools.Planning.plan_material_application(plan_spec, temp_dir)
```

### plan_animation/2

Plans animation sequences with temporal constraints.

```elixir
plan_spec = %{
  "animations" => [
    %{"object" => "Cube1", "property" => "location", "value" => [1, 0, 0], "frame" => 10},
    %{"object" => "Sphere1", "property" => "location", "value" => [2, 0, 0], "frame" => 20}
  ],
  "constraints" => [
    %{"type" => "temporal", "before" => "animation1", "after" => "animation2"}
  ],
  "total_frames" => 250
}

result = AriaForge.Tools.Planning.plan_animation(plan_spec, temp_dir)
```

## Available Domain Methods

The `create_forge_domain_spec()` provides these methods for goal decomposition:

### Scene Management
- **`create_forge_scene`**: Complete scene creation workflow
  - Supports `reset_first` and `introspect_first` options
  - Handles objects, materials, and rendering
  
- **`create_scene`**: Basic scene creation
  - Decomposes into object creation tasks
  
- **`introspect_scene`**: Get current scene information
  - Decomposes to `get_scene_info` command
  
- **`reset_and_prepare_scene`**: Reset scene and prepare for new work
  - Resets scene, then creates objects and applies materials
  
- **`prepare_clean_scene`**: Alias for `reset_and_prepare_scene`
  
- **`prepare_scene`**: Prepare scene with reset and FPS setting
  - Parameters: `fps` (default: 30), `introspect_before`, `introspect_after`, `objects`, `materials`
  - Decomposes to `reset_scene` and `set_scene_fps`
  - Optionally includes introspection and object/material creation

### Object Creation
- **`create_object`**: Create individual objects
  - Supports `type: "cube"` or `type: "sphere"`
  - Decomposes to `create_cube` or `create_sphere` commands

### Animation
- **`stacking_animation`**: Create a stacking animation with multiple objects
  - Parameters: `count`, `base_location`, `spacing`, `start_frame`, `frames_per_object`, `use_materials`
  - Decomposes to `animate_object` tasks for each object
  - Automatically assigns distinct colors to objects (Red, Green, Blue, etc.)
  - Example: `{"stacking_animation", %{"count" => 3, "base_location" => [0, 0, 0], "spacing" => 2.0}}`
  
- **`animate_object`**: Animate an object with keyframes
  - Handles dependency: ensures object exists before setting keyframes
  - Parameters: `object_name`, `object_type`, `start_location`, `keyframes`
  - Decomposes to `create_cube`/`create_sphere` then `set_keyframe` tasks
  - Method decomposition ensures object creation happens before keyframes

### Material Management
- **`apply_materials`**: Apply materials to objects
  - Decomposes to `set_material` commands
  
- **`setup_materials`**: Alias for `apply_materials`

### Rendering
- **`prepare_rendering`**: Prepare scene for rendering
  - Ensures scene is ready, then renders
  - Decomposes to `get_scene_info` and `render_image` commands

### API Introspection
- **`explore_blender_api`**: Explore Blender API paths
  - Decomposes to `introspect_blender` or `introspect_python` commands
  
- **`introspect_blender_api`**: Alias for `explore_blender_api`
  
- **`discover_blender_capabilities`**: Discover common Blender capabilities
  - Plans introspection of common API paths

## Available Domain Commands

The `create_forge_domain_spec()` provides these primitive commands:

- **`create_cube`**: Create a cube object
  - Args: `name`, `location`, `size`
  
- **`create_sphere`**: Create a sphere object
  - Args: `name`, `location`, `radius`
  
- **`set_material`**: Apply material to object
  - Args: `object_name`, `material_name`, `color`
  
- **`reset_scene`**: Reset scene to clean state
  - Args: none
  
- **`set_scene_fps`**: Set scene frame rate (FPS)
  - Args: `fps` (integer)
  
- **`get_scene_info`**: Get current scene information
  - Args: none
  
- **`set_keyframe`**: Set keyframe for animation
  - Args: `object`, `property`, `value`, `frame`
  - Pure state transformer - methods handle ensuring object exists first
  
- **`render_image`**: Render scene to image file
  - Args: `filepath`, `resolution_x`, `resolution_y`
  
- **`introspect_blender`**: Introspect Blender API object
  - Args: `object_path`
  
- **`introspect_python`**: Introspect Python object with prep code
  - Args: `object_path`, `prep_code`

## Plan Format

Plans are returned as JSON strings. When decoded, they have this structure:

```json
{
  "steps": [
    {
      "tool": "create_cube",
      "args": {
        "name": "Cube1",
        "location": [0, 0, 0],
        "size": 2.0
      },
      "dependencies": [],
      "description": "Create cube 'Cube1'"
    }
  ],
  "total_operations": 1,
  "planner": "run_lazy"
}
```

### Plan Steps

Each step contains:
- **`tool`**: The command/tool to execute
- **`args`**: Arguments for the tool
- **`dependencies`**: List of step IDs this step depends on (currently empty, handled by aria_planner)
- **`description`**: Human-readable description

## Executing Plans

After generating a plan, execute it using `execute_plan/2`:

```elixir
# Generate plan
{:ok, plan_json} = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)

# Execute plan
result = AriaForge.Tools.Planning.execute_plan(plan_json, temp_dir)

case result do
  {:ok, message} ->
    # Plan executed successfully
    IO.puts("Success: #{message}")
  {:error, reason} ->
    # Plan execution failed
    IO.puts("Error: #{reason}")
end
```

Execution results include duration information in ISO 8601 format (e.g., "PT1S" for 1 second).

## Error Handling

### When aria_planner is Unavailable

If `aria_planner` is not available, all planning functions return:

```elixir
{:error, "AriaPlanner not available. Planning requires aria_planner to be installed and available."}
```

**Action**: Ensure `aria_planner` is installed and available before attempting planning.

### When Planning Fails

If planning fails (e.g., invalid tasks, unsatisfiable constraints), functions return:

```elixir
{:error, "run_lazy failed: <error details>"}
```

**Action**: Review the error message, check task specifications, and verify constraints are satisfiable.

### When Plan Execution Fails

If plan execution fails (e.g., invalid tool, missing arguments), `execute_plan/2` returns:

```elixir
{:error, "Plan execution failed: <error details>"}
```

**Action**: Review the plan steps, verify tool names and arguments are correct.

## Method Decomposition and Dependencies

**Key Principle**: Dependencies are handled via method decomposition, not explicit constraints.

- **Commands** are pure state transformers (no preconditions)
- **Methods** handle dependencies by decomposing into ordered tasks
- The planner uses backtracking to ensure correct ordering
- No explicit dependency constraints needed in most cases

### Example: Animation Dependencies

```elixir
# stacking_animation decomposes to:
#   - animate_object('StackCube1', ...)
#   - animate_object('StackCube2', ...)
#   - animate_object('StackCube3', ...)

# Each animate_object decomposes to:
#   - create_cube('StackCube1', ...)  # Object must exist first
#   - set_keyframe('StackCube1', ...) # Then set keyframes
#   - set_keyframe('StackCube1', ...)

# The planner automatically ensures create_cube happens before set_keyframe
# through method decomposition and backtracking
```

## Best Practices

### 1. Always Check for aria_planner

Before attempting planning, verify `aria_planner` is available:

```elixir
if Code.ensure_loaded?(AriaPlanner) do
  # Proceed with planning
else
  # Handle error: aria_planner not available
end
```

### 2. Use Appropriate Domain

- Use `create_forge_domain_spec()` for comprehensive workflows
- Use `create_scene_domain_spec()` for simple scene construction
- Provide custom domain for specialized scenarios

### 3. Structure Tasks Hierarchically

Use high-level methods when possible:

```elixir
# Good: Use high-level method
{"create_forge_scene", %{"objects" => [...]}}

# Less ideal: Use low-level commands directly
{"create_cube", %{"name" => "Cube1"}}
```

### 4. Use Method Decomposition for Dependencies

Dependencies are handled automatically via method decomposition. Only use explicit constraints for:
- Temporal constraints (frame timing)
- Cross-method dependencies (rare)

```elixir
# Good: Let method decomposition handle dependencies
{"stacking_animation", %{"count" => 3}}  # Dependencies handled automatically

# Only use explicit constraints for temporal or cross-method cases
"constraints" => [
  %{"type" => "temporal", "total_frames" => 250}
]
```

### 5. Handle Errors Gracefully

Always handle both success and error cases:

```elixir
case AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir) do
  {:ok, plan_json} ->
    # Process plan
  {:error, reason} ->
    # Handle error appropriately
end
```

## Example Workflows

### Workflow 1: Create Scene with Reset

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"create_forge_scene", %{
      "reset_first" => true,
      "objects" => [
        %{"type" => "cube", "name" => "MainCube", "location" => [0, 0, 0], "size" => 2.0},
        %{"type" => "sphere", "name" => "MainSphere", "location" => [3, 0, 0], "radius" => 1.5}
      ],
      "materials" => [
        %{"name" => "RedMaterial", "color" => [1.0, 0.0, 0.0, 1.0], "objects" => ["MainCube"]},
        %{"name" => "BlueMaterial", "color" => [0.0, 0.0, 1.0, 1.0], "objects" => ["MainSphere"]}
      ]
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{}
}

{:ok, plan_json} = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
{:ok, result} = AriaForge.Tools.Planning.execute_plan(plan_json, temp_dir)
```

### Workflow 2: Introspect Scene Then Create Objects

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"introspect_scene", %{}},
    {"create_forge_scene", %{
      "objects" => [
        %{"type" => "cube", "name" => "NewCube", "location" => [0, 0, 0]}
      ]
    }}
  ],
  "constraints" => [
    %{"type" => "dependency", "from" => "introspect_scene", "to" => "create_forge_scene"}
  ],
  "domain" => nil,
  "opts" => %{}
}

{:ok, plan_json} = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
```

### Workflow 3: Stacking Animation with Materials

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"prepare_scene", %{"fps" => 30}},
    {"stacking_animation", %{
      "count" => 3,
      "base_location" => [0, 0, 0],
      "spacing" => 2.0,
      "start_frame" => 1,
      "frames_per_object" => 30,
      "use_materials" => true
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{}
}

{:ok, plan_json} = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
{:ok, result} = AriaForge.Tools.Planning.execute_plan(plan_json, temp_dir)
```

### Workflow 4: Render Scene

```elixir
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"create_forge_scene", %{
      "objects" => [
        %{"type" => "cube", "name" => "RenderCube", "location" => [0, 0, 0]}
      ],
      "render" => %{
        "filepath" => "/tmp/render.png",
        "resolution_x" => 1920,
        "resolution_y" => 1080
      }
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{}
}

{:ok, plan_json} = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
```

## Summary

- **Required**: `aria_planner` must be installed and available
- **Primary Function**: Use `run_lazy_planning/2` for all planning scenarios
- **Domain**: Use `create_forge_domain_spec()` for comprehensive workflows
- **Error Handling**: Always handle `{:error, reason}` cases
- **Execution**: Use `execute_plan/2` to execute generated plans
- **Dependencies**: Handled automatically via method decomposition and backtracking
- **Method Decomposition**: Methods decompose goals into ordered tasks, ensuring dependencies
- **No Fallbacks**: Planning will fail if `aria_planner` is unavailable

For more details, see the source code in `lib/aria_forge/tools/planning.ex`.
