# MCP Seed Prompts: Aria Planner Integration

This document contains seed prompts for MCP integration with aria-planner, extracted from the GitHub repository analysis.

## Repository Information
- **Repository**: https://github.com/V-Sekai-fire/aria-planner.git
- **License**: MIT
- **Language**: 100% Elixir
- **Status**: Active development, early stage (1 commit)

## Core Architecture Insights

### Project Structure
- **Library Code**: `lib/aria_planner/`
- **Tests**: Comprehensive test suite in `test/`
- **Database Migrations**: `priv/repo/migrations/`
- **Infrastructure**: Full project setup with Credo, Dialyzer, Formatter, Markdown linting, Pre-commit hooks

### Key Capabilities (Inferred from Structure)

1. **Planning Domain Operations**
   - Temporal STN (Simple Temporal Network) scheduling and operations
   - Domain-specific planning (Blocks World, PERT planning)
   - Goal-based and task-based planning approaches

2. **Entity Management**
   - Entity types (Persona, Movable objects)
   - Entity capabilities (movable entities)
   - State management for planning contexts

3. **Core Planning Components**
   - Planner state management
   - Plan execution state tracking
   - Plan generation and validation
   - Temporal conversion utilities
   - Planner metadata management

4. **Solvers**
   - Aria Goal Solver implementation
   - Backtracking algorithms (MCP backtracking)
   - Belief-based ego architecture integration

5. **MCP Integration**
   - MCP domain operations
   - Backtracking via MCP protocol
   - Domain operations test suite

## Seed Prompts for Using Aria Planner Tools with Blender/bpy

### Seed Prompt 1: Planning Blender Scene Construction
```
Use aria_planner MCP tools to plan a complex Blender scene construction.

Scenario: Create a scene with multiple objects that need to be placed in a specific sequence due to dependencies.

Example: 
- Initial state: Empty scene
- Goal: Scene with 5 cubes, 3 spheres, arranged in a specific pattern
- Constraints: Some objects must be created before others, materials must be applied in sequence

Steps:
1. Use aria_planner's problem creation tool to define the initial scene state and goal state
2. Use the planning domain tool to specify Blender operations as the domain (create_cube, create_sphere, set_material, etc.)
3. Call the planner to generate a sequence of bpy-mcp tool calls
4. Execute the plan by calling bpy-mcp tools in the planned order
5. Monitor execution and handle any failures by replanning

Show how to:
- Translate Blender scene goals into planning problems
- Use aria_planner to sequence bpy-mcp operations
- Handle dependencies between Blender operations
```

### Seed Prompt 2: Temporal Animation Planning
```
Use aria_planner's temporal STN tools to plan keyframe animations in Blender.

Scenario: Animate objects with temporal constraints and dependencies.

Example:
- Object A must move from position (0,0,0) to (10,0,0) over 100 frames
- Object B must start moving 50 frames after Object A, from (5,0,0) to (15,0,0) over 100 frames
- Object C must complete its animation before Object A finishes

Steps:
1. Use temporal_stn_operations tool to create a temporal network with frame constraints
2. Define temporal constraints: durations, precedences, deadlines for keyframe animations
3. Use temporal_stn_scheduling_operations to solve for frame timings
4. Generate plan with specific frame numbers for each keyframe
5. Execute plan by calling bpy-mcp tools to set keyframes at planned times

Show how to:
- Represent animation keyframes as temporal tasks
- Use temporal planning to sequence complex animations
- Handle frame timing constraints and dependencies
```

### Seed Prompt 3: Goal-Based Scene Composition
```
Use aria_planner's goal solver to decompose complex Blender scene goals.

Scenario: Create a scene that matches a description or reference image.

Example:
- Main goal: "Create a living room scene"
- Subgoals: Floor, walls, furniture, lighting, materials

Steps:
1. Use aria_goal_solver tool with high-level scene description
2. Goal solver decomposes into subgoals (create floor, add walls, place furniture, etc.)
3. Each subgoal is further decomposed into specific bpy-mcp operations
4. Execute the hierarchical plan by calling bpy-mcp tools in the planned order
5. Validate that final scene matches the original goal

Show how to:
- Express Blender scene descriptions as planning goals
- Use goal decomposition to plan scene construction
- Handle goal dependencies (e.g., walls before furniture placement)
```

### Seed Prompt 4: Entity-Based Asset Management
```
Use aria_planner's entity management to plan with Blender objects as entities.

Scenario: Manage scene objects as entities with capabilities and constraints.

Example:
- Entities: Cube1 (movable, can have materials), Sphere1 (movable), Light1 (positionable)
- Goal: Arrange entities in specific pattern respecting capabilities

Steps:
1. Use entity_management tool to register Blender objects as planning entities
2. Define entity capabilities (e.g., cube can be moved, scaled, materialized)
3. Query entity capabilities to understand what operations are possible
4. Create planning problem with entity constraints
5. Generate plan that respects entity capabilities
6. Execute by calling bpy-mcp tools that match entity capabilities

Show how to:
- Represent Blender objects as planning entities
- Use entity capabilities to constrain planning
- Plan operations that respect object properties
```

### Seed Prompt 5: Material Application Planning
```
Use aria_planner to sequence material application in complex scenes.

Scenario: Apply materials to multiple objects with dependencies (e.g., shared textures, material variations).

Example:
- 10 objects need materials
- Some materials depend on others (e.g., base material created first)
- Constraints: Material creation order, material assignment order

Steps:
1. Use domain-specific planning (custom Blender material domain) to model material dependencies
2. Create planning problem with initial state (no materials) and goal state (all objects have materials)
3. Use planner to generate sequence of set_material bpy-mcp calls
4. Execute material application plan
5. Validate all objects have correct materials

Show how to:
- Model material dependencies as planning constraints
- Use planning to optimize material application order
- Handle shared materials and material inheritance
```

### Seed Prompt 6: Render Pipeline Planning
```
Use aria_planner to plan complex rendering workflows.

Scenario: Plan a multi-pass rendering pipeline with dependencies.

Example:
- Initial setup (scene preparation)
- Multiple render passes (diffuse, specular, shadows)
- Post-processing (compositing, adjustments)
- Final output generation

Steps:
1. Use temporal planning to sequence render operations
2. Define constraints: some passes must complete before others
3. Plan render_image bpy-mcp calls with proper sequencing
4. Monitor execution and handle render failures
5. Adjust plan if render times differ from estimates

Show how to:
- Model rendering pipeline as temporal planning problem
- Use planning to optimize render order
- Handle render dependencies and resource constraints
```

### Seed Prompt 7: Procedural Generation Planning
```
Use aria_planner to plan procedural scene generation.

Scenario: Generate complex scenes using procedural rules and constraints.

Example:
- Goal: Generate city street scene
- Rules: Buildings follow height restrictions, spacing rules
- Constraints: Roads must connect, buildings must align

Steps:
1. Use goal-based planning to decompose procedural generation
2. Define generation rules as planning constraints
3. Generate plan with sequence of create operations
4. Execute plan using bpy-mcp tools
5. Validate generated scene meets procedural constraints

Show how to:
- Express procedural generation rules as planning constraints
- Use planning to coordinate procedural operations
- Validate procedural generation results
```

### Seed Prompt 8: Animation Sequence Planning
```
Use aria_planner's backtracking to plan complex animation sequences.

Scenario: Plan animation with multiple interdependent sequences.

Example:
- Character animation requires precise timing
- Some animations must backtrack if constraints aren't met
- Need to explore alternative animation paths

Steps:
1. Configure backtracking for animation planning (depth limits, strategies)
2. Use planner with backtracking enabled to explore animation options
3. Monitor search progress to find feasible animation sequences
4. Extract best animation plan from search results
5. Execute animation using bpy-mcp tools at planned keyframes

Show how to:
- Use backtracking to handle animation constraint conflicts
- Explore alternative animation sequences
- Select best animation plan from search results
```

### Seed Prompt 9: Scene Optimization Planning
```
Use aria_planner to plan scene optimizations and cleanup operations.

Scenario: Optimize existing scene by reorganizing objects and removing unused elements.

Example:
- Goal: Reduce scene complexity while maintaining visual quality
- Actions: Merge meshes, remove duplicates, optimize materials
- Constraints: Preserve visual appearance, maintain object relationships

Steps:
1. Use get_scene_info bpy-mcp tool to understand current scene state
2. Create planning problem: initial state (current scene), goal state (optimized scene)
3. Use planner to generate optimization plan
4. Execute optimization plan using bpy-mcp tools
5. Validate optimization maintains scene functionality

Show how to:
- Model scene optimization as planning problem
- Use planning to sequence optimization operations
- Handle optimization constraints and dependencies
```

### Seed Prompt 10: Complete Blender Workflow Planning
```
Use aria_planner to plan a complete Blender workflow from scene setup to final render.

Complete Workflow:
1. **Scene Setup**: Use planner to sequence scene initialization (reset, base objects)
2. **Object Creation**: Plan creation of all scene objects with dependencies
3. **Material Assignment**: Plan material application respecting material dependencies
4. **Lighting Setup**: Plan light placement and configuration
5. **Animation Setup**: Use temporal planning for keyframe sequences
6. **Render Planning**: Plan render passes and final output
7. **Execution Monitoring**: Monitor plan execution and handle failures

Steps:
1. Use aria_planner resources to discover available planning domains
2. Create comprehensive planning problem covering entire workflow
3. Use appropriate planner (goal-based, temporal, or domain-specific)
4. Execute complete plan using bpy-mcp tools
5. Monitor execution and replan if needed

Show how to:
- Combine multiple planning approaches for complex workflows
- Use planning resources to discover capabilities
- Execute complete planned workflows
- Handle workflow failures and replanning
```

## Usage Patterns for Blender/bpy Integration

### Pattern 1: Scene Construction Planning
```
1. Use aria_planner to create planning problem from Blender scene goals
2. Planner generates sequence of bpy-mcp operations
3. Execute plan by calling bpy-mcp tools in order
4. Validate scene matches goals using get_scene_info
```

### Pattern 2: Temporal Animation Planning
```
1. Define animation keyframes as temporal tasks
2. Use temporal_stn_operations to create temporal network
3. Solve for frame timings with temporal_stn_scheduling_operations
4. Execute animation using bpy-mcp at planned frame numbers
```

### Pattern 3: Goal Decomposition for Complex Scenes
```
1. Express scene description as high-level goal
2. Use aria_goal_solver to decompose into subgoals
3. Each subgoal maps to specific bpy-mcp operations
4. Execute hierarchical plan to build complete scene
```

### Pattern 4: Entity-Based Object Management
```
1. Register Blender objects as planning entities
2. Define object capabilities (movable, materializable, etc.)
3. Plan operations respecting entity capabilities
4. Execute operations using appropriate bpy-mcp tools
```

### Pattern 5: Dependency-Aware Operation Sequencing
```
1. Model Blender operations with dependencies (e.g., material before assignment)
2. Use planner to find valid operation sequences
3. Execute operations respecting dependencies
4. Handle failures by replanning
```

## Example Tool Call Sequences

### Example 1: Planned Scene Construction
```
1. aria_planner: create_problem(
     initial_state={"objects": []},
     goal={"objects": ["Cube1", "Sphere1", "Cube2"], "pattern": "stacked"}
   )
2. aria_planner: solve_plan(problem_id)
3. aria_planner: get_plan(plan_id) -> Returns: [
     {"tool": "bpy.create_cube", "args": {"name": "Cube1", "location": [0,0,0]}},
     {"tool": "bpy.create_sphere", "args": {"name": "Sphere1", "location": [0,0,2]}},
     {"tool": "bpy.create_cube", "args": {"name": "Cube2", "location": [0,0,4]}}
   ]
4. Execute each bpy-mcp tool call in sequence
```

### Example 2: Temporal Animation Plan
```
1. aria_planner: create_temporal_stn(
     tasks=[
       {"id": "move_cube", "duration": 100, "operation": "animate_position"},
       {"id": "rotate_sphere", "duration": 50, "operation": "animate_rotation"}
     ],
     constraints=[
       {"type": "precedence", "before": "move_cube", "after": "rotate_sphere", "min_delay": 25}
     ]
   )
2. aria_planner: solve_temporal_schedule(stn_id)
3. Get scheduled plan with frame numbers
4. Execute: bpy-mcp operations at specific frames
```

### Example 3: Material Application Plan
```
1. aria_planner: create_problem(
     domain="blender_materials",
     initial_state={"materials": [], "objects": ["Cube1", "Sphere1"]},
     goal={"materials": ["Mat1", "Mat2"], "assignments": {"Cube1": "Mat1", "Sphere1": "Mat2"}}
   )
2. aria_planner: solve_plan(problem_id) -> Plan with material creation before assignment
3. Execute: set_material calls in planned order
```

## Integration Workflow

1. **Problem Formulation**: Express Blender task as planning problem
2. **Planning**: Use aria_planner tools to generate plan
3. **Translation**: Map plan steps to bpy-mcp tool calls
4. **Execution**: Execute bpy-mcp tools according to plan
5. **Validation**: Verify results match goals using bpy-mcp queries
6. **Replanning**: If execution fails, update problem and replan

## Next Steps

1. Install/configure aria_planner MCP server
2. Test basic planning operations with simple Blender tasks
3. Build example workflows combining aria_planner and bpy-mcp
4. Document successful planning patterns
5. Create templates for common Blender planning scenarios

