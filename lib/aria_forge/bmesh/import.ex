# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh.Import do
  @moduledoc """
  BMesh import functionality for glTF with EXT_mesh_bmesh extension.
  """

  require Logger

  @type import_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Imports BMesh data from glTF JSON with EXT_mesh_bmesh extension.
  """
  @spec import_gltf_scene(String.t(), String.t()) :: AriaForge.Mesh.result()
  def import_gltf_scene(gltf_json, _temp_dir) do
    # Python/bpy removed - use mock implementation only
    AriaForge.BMesh.Mock.import_gltf_scene(gltf_json)
  end
end
