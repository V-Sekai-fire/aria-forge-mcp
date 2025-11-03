# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.ResourceStorage do
  @moduledoc """
  Resource storage for Blender scenes using AriaStorage.
  
  This module provides persistent storage for Blender scene resources,
  allowing scenes to be saved, retrieved, and managed as resources.
  """

  @doc """
  Store a Blender scene resource using AriaStorage.
  
  ## Parameters
  - `scene_id`: Unique identifier for the scene
  - `scene_data`: Scene data (can be JSON, BMesh, or file path)
  - `options`: Storage options
    - `:format`: Data format (:json, :bmesh, :file)
    - `:compression`: Compression algorithm (:zstd, :none)
  
  ## Returns
  - `{:ok, storage_ref}` - Storage reference for the scene
  - `{:error, reason}` - Error if storage fails
  """
  @spec store_scene_resource(String.t(), binary() | map() | String.t(), keyword()) :: 
    {:ok, String.t()} | {:error, String.t()}
  def store_scene_resource(scene_id, scene_data, options \\ []) do
    format = Keyword.get(options, :format, :json)
    compression = Keyword.get(options, :compression, :zstd)
    
    # Prepare data for storage
    data_to_store = case format do
      :json when is_map(scene_data) ->
        Jason.encode!(scene_data)
      
      :json when is_binary(scene_data) ->
        scene_data
      
      :file when is_binary(scene_data) ->
        case File.read(scene_data) do
          {:ok, data} -> data
          {:error, reason} -> {:error, "Failed to read file: #{reason}"}
        end
      
      _ ->
        {:error, "Unsupported format: #{format}"}
    end
    
    case data_to_store do
      {:error, reason} ->
        {:error, reason}
      
      data when is_binary(data) ->
        # Create temporary file for AriaStorage
        temp_file_result = create_temp_file(scene_id, data)
        
        case temp_file_result do
          {:error, reason} ->
            {:error, reason}
          
          temp_file when is_binary(temp_file) ->
            try do
              # Store using AriaStorage with chunking
              case AriaStorage.process_file(temp_file, 
                backend: :local,
                compression: compression,
                chunk_options: [avg_size: 64 * 1024]
              ) do
                {:ok, %{chunks: _chunks, index: _index, storage_result: storage_result}} ->
                  # Store metadata linking scene_id to storage_ref
                  _storage_ref = Map.get(storage_result, :chunk_id) || 
                    Map.get(storage_result, :file_ref) || 
                    "#{scene_id}_#{System.unique_integer([:positive])}"
                  
                  # Return scene_id as the storage reference for easier lookup
                  {:ok, scene_id}
                
                {:error, reason} ->
                  {:error, "AriaStorage failed: #{inspect(reason)}"}
              end
            after
              # Always clean up temp file, even on error
              if File.exists?(temp_file) do
                File.rm(temp_file)
              end
            end
        end
      
      _ ->
        {:error, "Invalid data format"}
    end
  end

  @doc """
  Retrieve a stored Blender scene resource.
  
  ## Parameters
  - `storage_ref`: Storage reference from store_scene_resource
  - `options`: Retrieval options
    - `:format`: Desired format (:json, :binary)
  
  ## Returns
  - `{:ok, data}` - Scene data
  - `{:error, reason}` - Error if retrieval fails
  """
  @spec get_scene_resource(String.t(), keyword()) :: 
    {:ok, binary() | map()} | {:error, String.t()}
  def get_scene_resource(storage_ref, options \\ []) do
    format = Keyword.get(options, :format, :json)
    
    case AriaStorage.get_file(storage_ref) do
      {:ok, data} ->
        case format do
          :json ->
            case Jason.decode(data) do
              {:ok, json} -> {:ok, json}
              _ -> {:ok, data}
            end
          
          :binary ->
            {:ok, data}
        end
      
      {:error, reason} ->
        {:error, "Failed to retrieve resource: #{inspect(reason)}"}
    end
  end

  @doc """
  List all stored scene resources.
  
  ## Parameters
  - `options`: List options
    - `:limit`: Maximum number of resources to return
  
  ## Returns
  - `{:ok, [resources]}` - List of storage references
  - `{:error, reason}` - Error if listing fails
  """
  @spec list_scene_resources(keyword()) :: 
    {:ok, list(String.t())} | {:error, String.t()}
  def list_scene_resources(options \\ []) do
    limit = Keyword.get(options, :limit, 100)
    
    case AriaStorage.list_files(limit: limit) do
      {:ok, files} ->
        refs = Enum.map(files, fn file ->
          Map.get(file, :chunk_id) || Map.get(file, :file_ref) || Map.get(file, :id) || 
          Map.get(file, "chunk_id") || Map.get(file, "file_ref") || Map.get(file, "id")
        end)
        {:ok, refs}
      
      {:error, reason} ->
        {:error, "Failed to list resources: #{inspect(reason)}"}
    end
  end

  @doc """
  Delete a stored scene resource.
  
  ## Parameters
  - `storage_ref`: Storage reference to delete
  
  ## Returns
  - `:ok` - Resource deleted
  - `{:error, reason}` - Error if deletion fails
  """
  @spec delete_scene_resource(String.t()) :: :ok | {:error, String.t()}
  def delete_scene_resource(storage_ref) do
    # AriaStorage uses Waffle for chunk storage
    # The storage_ref might be a chunk_id or file_ref
    # We need to delete through the chunk store interface
    # Since we're using local backend, we can try to delete directly via file system
    # or use AriaStorage's delete_chunk if we have access to the chunk store
    
    # Try to use AriaStorage.delete_chunk which requires a chunk store struct
    # For now, we'll attempt deletion via the file system since we're using local storage
    storage_dir = Path.join(System.user_home!(), ".bpy_mcp/storage")
    chunk_path = Path.join(storage_dir, "chunks")
    
    # Try to find and delete the chunk file
    # Chunks are stored in subdirectories based on prefix
    case find_and_delete_chunk_file(chunk_path, storage_ref) do
      :ok -> :ok
      {:error, :not_found} ->
        # If file deletion fails, the resource might not exist or be stored differently
        {:error, "Resource not found or delete not fully implemented for storage reference format"}
      {:error, reason} ->
        {:error, "Failed to delete resource: #{inspect(reason)}"}
    end
  end
  
  # Helper to find and delete chunk file
  defp find_and_delete_chunk_file(chunk_dir, chunk_id) when is_binary(chunk_id) do
    # Chunks are stored with 2-character prefix directories
    if String.length(chunk_id) >= 2 do
      prefix = String.slice(chunk_id, 0, 2)
      prefix_dir = Path.join(chunk_dir, prefix)
      chunk_filename = "#{chunk_id}.cacnk"
      chunk_file = Path.join(prefix_dir, chunk_filename)
      
      if File.exists?(chunk_file) do
        case File.rm(chunk_file) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end
      else
        {:error, :not_found}
      end
    else
      {:error, :invalid_chunk_id}
    end
  end

  # Private helpers

  defp create_temp_file(scene_id, data) do
    temp_dir = System.tmp_dir!()
    filename = "bpy_scene_#{scene_id}_#{System.unique_integer([:positive])}.json"
    temp_path = Path.join(temp_dir, filename)
    
    case File.write(temp_path, data) do
      :ok -> temp_path
      {:error, reason} -> {:error, "Failed to create temp file: #{reason}"}
    end
  end
end

