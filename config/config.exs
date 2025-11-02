# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure Pythonx to install Blender Python API
config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "mcp_bpy"
  version = "0.1.0"
  requires-python = "==3.12.*"
  dependencies = [
    "bpy>=4.5.4"
  ]
  """
