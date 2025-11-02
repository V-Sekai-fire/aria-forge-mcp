# BpyMcp

A Model Context Protocol (MCP) server that provides Blender Python (bpy) tools for 3D modeling and rendering operations. This server allows MCP clients to interact with Blender through a standardized protocol, enabling programmatic control of 3D scenes, objects, materials, and rendering.

## Features

- **Object Creation**: Create cubes and spheres with customizable parameters
- **Material Management**: Apply materials with custom colors to objects
- **Scene Rendering**: Render scenes to image files with configurable resolution
- **Scene Information**: Query current scene details including objects and settings
- **Mock Mode**: Fallback functionality when Python/Blender is not available

## MCP Tools

- `bpy_create_cube`: Create a cube object in the Blender scene
- `bpy_create_sphere`: Create a sphere object in the Blender scene
- `bpy_set_material`: Apply a material to an existing object
- `bpy_render_image`: Render the current scene to an image file
- `bpy_get_scene_info`: Retrieve information about the current scene

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bpy_mcp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bpy_mcp, "~> 0.1.0"}
  ]
end
```

## Docker Setup

The project includes Docker support for both development and production environments.

### Prerequisites

- Docker and Docker Compose
- At least 4GB of available RAM for Blender operations

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd bpy-mcp

# Start development environment
./docker-run.sh dev

# Or start production environment
./docker-run.sh prod
```

### Development

```bash
# Start development server with hot reload
./docker-run.sh dev

# View logs
./docker-run.sh logs -f

# Open shell in container
./docker-run.sh shell

# Stop development server
./docker-run.sh stop
```

### Production

```bash
# Build and start production server
./docker-run.sh prod

# View production logs
./docker-run.sh logs

# Stop production server
docker-compose -f docker-compose.prod.yml down
```

### Manual Docker Commands

```bash
# Development
docker-compose up --build

# Production
docker-compose -f docker-compose.prod.yml up -d --build

# Clean up
docker-compose down -v
```

### Architecture

The Docker setup uses a multi-stage build:

- **Base**: Common dependencies (Erlang, Elixir, Blender)
- **Builder** (sidecar): Builds the Elixir release (discarded after build)
- **Runtime**: Minimal production image with only the release

This approach minimizes the final image size while ensuring reproducible builds.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bpy_mcp>.
