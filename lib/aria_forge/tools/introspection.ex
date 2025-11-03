# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Introspection do
  @moduledoc """
  Introspection tools for examining APIs (read-only, metadata only).
  Note: Python/bpy functionality removed - mock implementations only.
  """

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Introspects structure for debugging and understanding API.
  Metadata only - no property access, no side effects.
  """
  @spec introspect_blender(String.t(), String.t()) :: result()
  def introspect_blender(object_path \\ "bmesh", temp_dir) do
    {:ok, "Introspection of #{object_path}: API not available"}
  end

  @doc """
  Introspects any Python object/API structure for debugging and understanding Python APIs.
  Note: Python functionality removed - mock implementation only.
  """
  @spec introspect_python(String.t(), String.t() | nil, String.t()) :: result()
  def introspect_python(object_path, prep_code \\ nil, temp_dir) do
    {:ok, "Introspection of #{object_path}: Python API not available"}
  end
end
