# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Objects do
  @moduledoc """
  Object creation tools using bmesh primitives (cubes, spheres, etc.)
  Uses MCP Blender tools - fails if Blender MCP is not available.
  """

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a cube object in the scene using bmesh primitives.
  Fails if MCP Blender is not available.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: result()
  def create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, _temp_dir) do
    [x, y, z] = location
    half_size = size / 2.0
    code = """
import bpy
import bmesh

# Create a new mesh and object
mesh = bpy.data.meshes.new(name='#{name}')
obj = bpy.data.objects.new('#{name}', mesh)

# Add object to the scene collection
bpy.context.collection.objects.link(obj)

# Create bmesh
bm = bmesh.new()

# Create 8 vertices for a cube
# Bottom face (z = -half_size)
v1 = bm.verts.new((-#{half_size}, -#{half_size}, -#{half_size}))
v2 = bm.verts.new((#{half_size}, -#{half_size}, -#{half_size}))
v3 = bm.verts.new((#{half_size}, #{half_size}, -#{half_size}))
v4 = bm.verts.new((-#{half_size}, #{half_size}, -#{half_size}))
# Top face (z = half_size)
v5 = bm.verts.new((-#{half_size}, -#{half_size}, #{half_size}))
v6 = bm.verts.new((#{half_size}, -#{half_size}, #{half_size}))
v7 = bm.verts.new((#{half_size}, #{half_size}, #{half_size}))
v8 = bm.verts.new((-#{half_size}, #{half_size}, #{half_size}))

# Update bmesh indices
bm.verts.ensure_lookup_table()

# Create 6 faces
# Bottom face
bm.faces.new([v1, v2, v3, v4])
# Top face
bm.faces.new([v8, v7, v6, v5])
# Front face
bm.faces.new([v2, v6, v7, v3])
# Back face
bm.faces.new([v4, v8, v5, v1])
# Right face
bm.faces.new([v3, v7, v8, v4])
# Left face
bm.faces.new([v1, v5, v6, v2])

# Transform to location
bmesh.ops.translate(bm, vec=(#{x}, #{y}, #{z}), verts=bm.verts[:])

# Update mesh from bmesh
bm.to_mesh(mesh)
bm.free()

# Update mesh
mesh.update()

result = f"Created cube '#{name}' at (#{x}, #{y}, #{z}) with size #{size}"
result
"""

    case mcp_blender_execute_blender_code(code: code) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, "Failed to create cube via MCP Blender: #{inspect(reason)}"}

      other ->
        {:error, "MCP Blender not available: #{inspect(other)}"}
    end
  rescue
    e -> {:error, "Error creating cube: #{Exception.message(e)}"}
  end

  @doc """
  Creates a tapered capsule object in the scene using bmesh primitives.
  A tapered capsule consists of a cylindrical middle section and two hemispherical caps.
  Fails if MCP Blender is not available.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: result()
  def create_sphere(name \\ "TaperedCapsule", location \\ [0, 0, 0], radius \\ 1.0, _temp_dir) do
    [x, y, z] = location
    # Tapered capsule parameters (using radius as default for both, can be made configurable)
    height = radius * 2.0  # Default height is 2x radius
    radius_bottom = radius
    radius_top = radius
    # Use reasonable segment counts
    u_segments = 32  # Segments around the circumference
    v_hemisphere_segments = 8  # Segments for each hemisphere
    v_cylinder_segments = 4  # Segments for the middle cylinder
    
    code = """
import bpy
import bmesh
import math

# Create a new mesh and object
mesh = bpy.data.meshes.new(name='#{name}')
obj = bpy.data.objects.new('#{name}', mesh)

# Add object to the scene collection
bpy.context.collection.objects.link(obj)

# Create bmesh
bm = bmesh.new()

# Tapered capsule parameters
height = #{height}
radius_bottom = #{radius_bottom}
radius_top = #{radius_top}
u_segments = #{u_segments}
v_hemisphere_segments = #{v_hemisphere_segments}
v_cylinder_segments = #{v_cylinder_segments}

half_height = height / 2.0
verts = []

# Create bottom hemisphere (centered at -half_height along Y)
# From bottom pole to equator (y from -half_height - radius_bottom to -half_height)
for i in range(v_hemisphere_segments):
    v_angle = math.pi * (i + 1) / (2 * v_hemisphere_segments)  # pi/2 to 0 (from pole to equator)
    y_offset = -math.cos(v_angle) * radius_bottom
    ring_radius = math.sin(v_angle) * radius_bottom
    y_pos = -half_height + y_offset
    
    for j in range(u_segments):
        u_angle = 2 * math.pi * j / u_segments
        x_pos = ring_radius * math.cos(u_angle)
        z_pos = ring_radius * math.sin(u_angle)
        vert = bm.verts.new((x_pos, y_pos, z_pos))
        verts.append(vert)

# Create cylindrical middle section (tapering from bottom to top)
# From -half_height to +half_height
for i in range(v_cylinder_segments):
    t = (i + 1) / (v_cylinder_segments + 1)  # 0 to 1
    current_radius = radius_bottom + (radius_top - radius_bottom) * t
    y_pos = -half_height + height * t
    
    for j in range(u_segments):
        u_angle = 2 * math.pi * j / u_segments
        x_pos = current_radius * math.cos(u_angle)
        z_pos = current_radius * math.sin(u_angle)
        vert = bm.verts.new((x_pos, y_pos, z_pos))
        verts.append(vert)

# Create top hemisphere (centered at +half_height along Y)
# From equator to top pole (y from +half_height to +half_height + radius_top)
for i in range(v_hemisphere_segments):
    v_angle = math.pi * (v_hemisphere_segments - i) / (2 * v_hemisphere_segments)  # pi/2 to 0 (from equator to pole)
    y_offset = -math.cos(v_angle) * radius_top
    ring_radius = math.sin(v_angle) * radius_top
    y_pos = half_height + y_offset
    
    for j in range(u_segments):
        u_angle = 2 * math.pi * j / u_segments
        x_pos = ring_radius * math.cos(u_angle)
        z_pos = ring_radius * math.sin(u_angle)
        vert = bm.verts.new((x_pos, y_pos, z_pos))
        verts.append(vert)

# Add bottom pole vertex
bottom_pole = bm.verts.new((0, -half_height - radius_bottom, 0))
verts.append(bottom_pole)

# Add top pole vertex
top_pole = bm.verts.new((0, half_height + radius_top, 0))
verts.append(top_pole)

# Update bmesh indices
bm.verts.ensure_lookup_table()

# Create faces for bottom hemisphere
# Bottom pole connects to first ring
for j in range(u_segments):
    v1_idx = j
    v2_idx = (j + 1) % u_segments
    v1 = verts[v1_idx]
    v2 = verts[v2_idx]
    bm.faces.new([bottom_pole, v2, v1])

# Rest of bottom hemisphere
for i in range(v_hemisphere_segments - 1):
    for j in range(u_segments):
        v1_idx = i * u_segments + j
        v2_idx = i * u_segments + (j + 1) % u_segments
        v3_idx = (i + 1) * u_segments + (j + 1) % u_segments
        v4_idx = (i + 1) * u_segments + j
        
        v1 = verts[v1_idx]
        v2 = verts[v2_idx]
        v3 = verts[v3_idx]
        v4 = verts[v4_idx]
        
        bm.faces.new([v1, v2, v3, v4])

# Create faces for cylindrical middle section
cylinder_start_idx = v_hemisphere_segments * u_segments
for i in range(v_cylinder_segments):
    for j in range(u_segments):
        v1_idx = cylinder_start_idx + i * u_segments + j
        v2_idx = cylinder_start_idx + i * u_segments + (j + 1) % u_segments
        v3_idx = cylinder_start_idx + (i + 1) * u_segments + (j + 1) % u_segments
        v4_idx = cylinder_start_idx + (i + 1) * u_segments + j
        
        v1 = verts[v1_idx]
        v2 = verts[v2_idx]
        v3 = verts[v3_idx]
        v4 = verts[v4_idx]
        
        bm.faces.new([v1, v2, v3, v4])

# Create faces for top hemisphere
top_hemisphere_start_idx = (v_hemisphere_segments + v_cylinder_segments) * u_segments
for i in range(v_hemisphere_segments - 1):
    for j in range(u_segments):
        v1_idx = top_hemisphere_start_idx + i * u_segments + j
        v2_idx = top_hemisphere_start_idx + i * u_segments + (j + 1) % u_segments
        v3_idx = top_hemisphere_start_idx + (i + 1) * u_segments + (j + 1) % u_segments
        v4_idx = top_hemisphere_start_idx + (i + 1) * u_segments + j
        
        v1 = verts[v1_idx]
        v2 = verts[v2_idx]
        v3 = verts[v3_idx]
        v4 = verts[v4_idx]
        
        bm.faces.new([v1, v2, v3, v4])

# Top pole connects to last ring
last_ring_start = top_hemisphere_start_idx + (v_hemisphere_segments - 1) * u_segments
for j in range(u_segments):
    v1_idx = last_ring_start + j
    v2_idx = last_ring_start + (j + 1) % u_segments
    v1 = verts[v1_idx]
    v2 = verts[v2_idx]
    bm.faces.new([v1, v2, top_pole])

# Transform to location
bmesh.ops.translate(bm, vec=(#{x}, #{y}, #{z}), verts=bm.verts[:])

# Update mesh from bmesh
bm.to_mesh(mesh)
bm.free()

# Update mesh
mesh.update()

result = f"Created tapered capsule '#{name}' at (#{x}, #{y}, #{z}) with height={height}, radiusBottom={radius_bottom}, radiusTop={radius_top}"
result
"""

    case mcp_blender_execute_blender_code(code: code) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, "Failed to create sphere via MCP Blender: #{inspect(reason)}"}

      other ->
        {:error, "MCP Blender not available: #{inspect(other)}"}
    end
  rescue
    e -> {:error, "Error creating sphere: #{Exception.message(e)}"}
  end
end
