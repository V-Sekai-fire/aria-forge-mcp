# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService.Helpers do
  @moduledoc """
  Helper functions for NativeService.
  
  Provides utility functions for URI parsing, scene resource handling,
  and response formatting.
  """

  alias BpyMcp.NativeService.Context
  alias BpyMcp.ResourceStorage

  @doc """
  Helper function to create text content for MCP responses.
  """
  @spec text_content(String.t()) :: map()
  def text_content(content) when is_binary(content) do
    %{"type" => "text", "text" => content}
  end

  @doc """
  Parse a scene URI to extract the scene_id.
  
  ## Examples
      iex> parse_scene_uri("blender://scene/my_scene")
      {:ok, "my_scene"}
      
      iex> parse_scene_uri("invalid://uri")
      {:error, "Invalid URI format. Expected: blender://scene/{scene_id}"}
  """
  @spec parse_scene_uri(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def parse_scene_uri("blender://scene/" <> scene_id) when scene_id != "" do
    {:ok, scene_id}
  end
  def parse_scene_uri(_uri), do: {:error, "Invalid URI format. Expected: blender://scene/{scene_id}"}

  @doc """
  Store scene data to AriaStorage for persistence.
  
  Creates an async backup copy of the scene.
  """
  @spec store_scene_to_aria_storage(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def store_scene_to_aria_storage(scene_id, scene_data) do
    case ResourceStorage.store_scene_resource(scene_id, scene_data, 
      format: :json, 
      compression: :zstd
    ) do
      {:ok, storage_ref} ->
        {:ok, storage_ref}
      
      {:error, reason} ->
        # Log error but don't fail the request
        {:error, reason}
    end
  end

  @doc """
  Get scene resource data by scene_id.
  
  Returns scene information including context token and scene info from Blender.
  """
  @spec get_scene_resource(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_scene_resource(scene_id) do
    case Registry.lookup(BpyMcp.SceneRegistry, scene_id) do
      [{pid, _}] ->
        if Process.alive?(pid) do
          # Get scene info from the scene manager
          scene_id_actual = Context.get_scene_id(pid)
          
          # Try to get scene info via BpyTools
          # First, get or create a temp dir for this context
          temp_dir = Context.create_temp_dir()
          
          # Generate context token for this scene
          context_token = 
            case Context.encode_context_token(pid, %{scene_id: scene_id_actual, operation_count: 0}) do
              {:ok, token} -> token
              _ -> nil
            end
          
          case BpyMcp.BpyTools.get_scene_info(temp_dir) do
            {:ok, scene_info} ->
              # Combine scene manager info with Blender scene info
              resource_data = %{
                scene_id: scene_id_actual,
                pid: :erlang.pid_to_list(pid) |> List.to_string(),
                status: "active",
                context_token: context_token,
                scene_info: scene_info
              }
              
              # Store to AriaStorage for persistence (async, don't wait)
              Task.start(fn ->
                store_scene_to_aria_storage(scene_id_actual, resource_data)
              end)
              
              {:ok, resource_data}
            
            {:error, _reason} ->
              # Fallback to basic info if Blender query fails
              resource_data = %{
                scene_id: scene_id_actual,
                pid: :erlang.pid_to_list(pid) |> List.to_string(),
                status: "active",
                context_token: context_token,
                note: "Scene exists but detailed info unavailable"
              }
              
              # Store to AriaStorage for persistence (async, don't wait)
              Task.start(fn ->
                store_scene_to_aria_storage(scene_id_actual, resource_data)
              end)
              
              {:ok, resource_data}
          end
        else
          {:error, "Scene context process is not alive"}
        end
      
      [] ->
        {:error, "Scene not found: #{scene_id}"}
    end
  end
end

