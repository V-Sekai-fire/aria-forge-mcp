# bpy-mcp Dev Container

This dev container provides a complete development environment for the bpy-mcp project.

## What's included

- Elixir 1.17.3 with OTP 26
- Erlang/OTP 26
- Python 3 with uv package manager
- Hex package manager (pre-installed)
- All project dependencies
- **lazygit** - Terminal UI for git operations
- VS Code extensions for Elixir development (including GitLens for enhanced git functionality)

## Getting started

1. Make sure you have Docker and the Dev Containers extension installed in VS Code
2. Open this project in VS Code
3. When prompted, click "Reopen in Container" or use Command Palette: "Dev Containers: Reopen in Container"
4. The container will build and set up the environment automatically

## Development

Once the container is running, you can:

- Run `mix test` to run tests
- Run `mix compile` to compile the project
- Run `mix run -e BpyMcp.StdioServer.start_link([])` to start the MCP server
- Use the integrated terminal for any development tasks

## Git Tools

- **lazygit**: Run `lazygit` in the terminal for an interactive git interface
- **GitLens**: Use the GitLens extension in VS Code for advanced git operations and history visualization

## Architecture

The container uses x86_64 architecture to ensure compatibility with the bpy Python package, which only provides wheels for x86_64 Linux platforms.
