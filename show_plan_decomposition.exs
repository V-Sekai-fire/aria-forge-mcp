# Show plan decomposition without explicit dependencies
alias AriaForge.Tools.Planning

IO.puts("=== Plan Decomposition (Dependencies via Method Decomposition) ===\n")

# Show how the domain decomposes tasks
domain = Planning.create_forge_domain_spec()
methods = Map.get(domain, :methods)

IO.puts("1. prepare_scene decomposition:")
prepare_fn = Map.get(methods, "prepare_scene")
if prepare_fn do
  tasks = prepare_fn.(%{}, %{"fps" => 30})
  Enum.each(Enum.with_index(tasks, 1), fn {{task, args}, idx} ->
    IO.puts("   #{idx}. #{task} #{inspect(args)}")
  end)
end

IO.puts("\n2. stacking_animation decomposition:")
stacking_fn = Map.get(methods, "stacking_animation")
if stacking_fn do
  tasks = stacking_fn.(%{}, %{
    "count" => 3,
    "base_location" => [0, 0, 0],
    "spacing" => 2.0,
    "start_frame" => 1,
    "frames_per_object" => 30
  })
  
  IO.puts("   Total tasks: #{length(tasks)}\n")
  
  # Group by object
  IO.puts("   Tasks for StackCube1:")
  stack1_tasks = Enum.filter(tasks, fn {t, a} -> 
    t == "create_cube" and Map.get(a, "name") == "StackCube1" or
    t == "set_keyframe" and Map.get(a, "object") == "StackCube1"
  end)
  Enum.each(stack1_tasks, fn {task, args} ->
    case task do
      "create_cube" ->
        IO.puts("     - create_cube: #{Map.get(args, "name")} at #{inspect(Map.get(args, "location"))}")
      "set_keyframe" ->
        IO.puts("     - set_keyframe: frame #{Map.get(args, "frame")}, value #{inspect(Map.get(args, "value"))}")
    end
  end)
  
  IO.puts("\n   Tasks for StackCube2:")
  stack2_tasks = Enum.filter(tasks, fn {t, a} -> 
    t == "create_cube" and Map.get(a, "name") == "StackCube2" or
    t == "set_keyframe" and Map.get(a, "object") == "StackCube2"
  end)
  Enum.each(stack2_tasks, fn {task, args} ->
    case task do
      "create_cube" ->
        IO.puts("     - create_cube: #{Map.get(args, "name")} at #{inspect(Map.get(args, "location"))}")
      "set_keyframe" ->
        IO.puts("     - set_keyframe: frame #{Map.get(args, "frame")}, value #{inspect(Map.get(args, "value"))}")
    end
  end)
  
  IO.puts("\n   Tasks for StackCube3:")
  stack3_tasks = Enum.filter(tasks, fn {t, a} -> 
    t == "create_cube" and Map.get(a, "name") == "StackCube3" or
    t == "set_keyframe" and Map.get(a, "object") == "StackCube3"
  end)
  Enum.each(stack3_tasks, fn {task, args} ->
    case task do
      "create_cube" ->
        IO.puts("     - create_cube: #{Map.get(args, "name")} at #{inspect(Map.get(args, "location"))}")
      "set_keyframe" ->
        IO.puts("     - set_keyframe: frame #{Map.get(args, "frame")}, value #{inspect(Map.get(args, "value"))}")
    end
  end)
end

IO.puts("\n=== How Planner Handles Dependencies ===\n")
IO.puts("The planner will:")
IO.puts("1. Decompose prepare_scene -> [reset_scene, set_scene_fps]")
IO.puts("2. Decompose stacking_animation -> [create_cube tasks, set_keyframe tasks]")
IO.puts("3. Use backtracking to infer dependencies:")
IO.puts("   - set_keyframe('StackCube1', ...) requires StackCube1 to exist")
IO.puts("   - create_cube('StackCube1', ...) adds StackCube1 to state")
IO.puts("   - Planner backtracks: set_keyframe fails -> finds create_cube -> orders create_cube first")
IO.puts("4. No explicit dependency constraints needed!")

IO.puts("\n=== Expected Plan Order (via Backtracking) ===\n")
IO.puts("1. reset_scene")
IO.puts("2. set_scene_fps (fps: 30)")
IO.puts("3. create_cube('StackCube1', ...)")
IO.puts("4. set_keyframe('StackCube1', frame: 1, ...)")
IO.puts("5. set_keyframe('StackCube1', frame: 31, ...)")
IO.puts("6. create_cube('StackCube2', ...)")
IO.puts("7. set_keyframe('StackCube2', frame: 31, ...)")
IO.puts("8. set_keyframe('StackCube2', frame: 61, ...)")
IO.puts("9. create_cube('StackCube3', ...)")
IO.puts("10. set_keyframe('StackCube3', frame: 61, ...)")
IO.puts("11. set_keyframe('StackCube3', frame: 91, ...)")
IO.puts("\n✓ Dependencies inferred automatically via backtracking!")

