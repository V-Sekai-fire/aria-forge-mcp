# Stacking Animation Demo with Backtracking Planning

## Overview

This demo demonstrates a stacking animation workflow that uses backtracking planning to handle dependencies between object creation and keyframe animation.

## What Was Accomplished

### 1. Domain Method: `stacking_animation`

Added to the planning domain in `lib/aria_forge/tools/planning.ex`:

- **Purpose**: Creates objects and animates them stacking on top of each other
- **Backtracking**: Ensures objects are created before keyframes are set
- **Parameters**:
  - `count`: Number of objects to stack (default: 3)
  - `base_location`: Starting position [x, y, z] (default: [0, 0, 0])
  - `spacing`: Vertical spacing between objects (default: 2.0)
  - `start_frame`: First frame of animation (default: 1)
  - `frames_per_object`: Frames per object animation (default: 30)

### 2. Command: `set_keyframe`

Added to the planning domain:

- **Purpose**: Sets keyframes for object properties at specific frames
- **Parameters**:
  - `object`: Object name
  - `property`: Property to animate (e.g., "location")
  - `value`: Value at this keyframe
  - `frame`: Frame number

### 3. Execution Results

Successfully executed a stacking animation:

- **Created 3 cubes**: StackCube1, StackCube2, StackCube3
- **Starting positions**: Below their final positions (z: -2.0, -4.0, -6.0)
- **Final positions**: Stacked vertically (z: 0.0, 2.0, 4.0)
- **Keyframes set**:
  - StackCube1: frames 1-31
  - StackCube2: frames 31-61
  - StackCube3: frames 61-91
- **Timeline**: 121 frames total

## Planning Domain Structure

The `stacking_animation` method decomposes into:

1. **Object Creation Tasks** (must happen first):
   - `create_cube` for each object at starting position

2. **Keyframe Tasks** (depend on objects existing):
   - `set_keyframe` at start frame
   - `set_keyframe` at end frame

## Backtracking Behavior

The planner uses backtracking to ensure:

- Objects are created before keyframes reference them
- Keyframes are scheduled with proper temporal constraints
- Dependencies are respected (e.g., `prepare_scene` before `stacking_animation`)

## Usage Example

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
      "frames_per_object" => 30
    }}
  ],
  "constraints" => [
    %{"type" => "dependency", "from" => "prepare_scene", "to" => "stacking_animation"}
  ],
  "opts" => %{
    "backtracking" => true
  }
}

{:ok, plan_json} = AriaForge.Tools.Planning.run_lazy_planning(plan_spec, temp_dir)
{:ok, result} = AriaForge.Tools.Planning.execute_plan(plan_json, temp_dir)
```

## Files Modified

1. `lib/aria_forge/tools/planning.ex`:
   - Added `stacking_animation` method
   - Added `set_keyframe` command
   - Added execution handler for `set_keyframe`

2. `lib/aria_forge/tools/animation.ex` (new):
   - Created Animation module with `set_keyframe` function

3. `lib/aria_forge/tools/planning/execution.ex`:
   - Added `set_keyframe` execution handler

4. `lib/aria_forge/tools.ex`:
   - Added Animation to aliases

## Next Steps

To use this in a real planning scenario:

1. Ensure `aria_planner` is installed
2. Call `run_lazy_planning` with `stacking_animation` task
3. The planner will use backtracking to order operations correctly
4. Execute the plan to create and animate the stacked objects

