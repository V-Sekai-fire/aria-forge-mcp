# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService.Resources do
  @moduledoc """
  Resource handling for MCP resources/list and resources/read requests.
  
  Manages listing and reading of both active scene contexts and stored resources.
  """

  alias BpyMcp.NativeService.Context
  alias BpyMcp.NativeService.Helpers
  alias BpyMcp.ResourceStorage
  require Jason

  @doc """
  Handles resources/list MCP request.
  
  Returns list of all active scene contexts and stored resources.
  """
  @spec handle_resources_list(map(), map()) :: {:reply, map(), map()}
  def handle_resources_list(request, state) do
    # List all active Blender scene contexts as resources
    active_resources = 
      case BpyMcp.list_contexts() do
        {:ok, contexts} ->
          Enum.map(contexts, fn %{scene_id: scene_id, pid: pid, operation_count: op_count} ->
            # Generate context token for this scene to include in resource
            context_token = 
              case Context.encode_context_token(pid, %{scene_id: scene_id, operation_count: op_count}) do
                {:ok, token} -> token
                _ -> nil
              end
            
            %{
              "uri" => "blender://scene/#{scene_id}",
              "name" => "Scene: #{scene_id}",
              "description" => "Blender scene context with #{op_count} operations#{if context_token, do: " (context_token available)", else: ""}",
              "mimeType" => "application/json"
            }
          end)
        
        {:error, _reason} ->
          []
      end
    
    # Also list stored resources from AriaStorage
    stored_resources =
      case ResourceStorage.list_scene_resources(limit: 100) do
        {:ok, storage_refs} ->
          Enum.map(storage_refs, fn storage_ref ->
            %{
              "uri" => "blender://stored/#{storage_ref}",
              "name" => "Stored Scene: #{storage_ref}",
              "description" => "Persisted Blender scene resource stored in AriaStorage",
              "mimeType" => "application/json"
            }
          end)
        
        {:error, _reason} ->
          []
      end
    
    # Combine active and stored resources
    all_resources = active_resources ++ stored_resources
    
    id = Map.get(request, "id", nil)
    response = 
      %{
        "jsonrpc" => "2.0",
        "result" => %{
          "resources" => all_resources
        }
      }
      |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
    
    {:reply, response, state}
  end

  @doc """
  Handles resources/read MCP request.
  
  Reads a resource by URI, supporting both active scenes and stored resources.
  """
  @spec handle_resources_read(map(), map(), map()) :: {:reply, map(), map()}
  def handle_resources_read(request, params, state) do
    uri = Map.get(params, "uri", "")
    
    cond do
      # Handle stored resources from AriaStorage
      String.starts_with?(uri, "blender://stored/") ->
        storage_ref = String.replace_prefix(uri, "blender://stored/", "")
        case ResourceStorage.get_scene_resource(storage_ref, format: :json) do
          {:ok, content} ->
            id = Map.get(request, "id", nil)
            response = 
              %{
                "jsonrpc" => "2.0",
                "result" => %{
                  "contents" => [
                    %{
                      "uri" => uri,
                      "mimeType" => "application/json",
                      "text" => if(is_map(content), do: Jason.encode!(content), else: content)
                    }
                  ]
                }
              }
              |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
            
            {:reply, response, state}
          
          {:error, reason} ->
            id = Map.get(request, "id", nil)
            response = 
              %{
                "jsonrpc" => "2.0",
                "error" => %{
                  "code" => -32603,
                  "message" => "Failed to read stored resource: #{reason}"
                }
              }
              |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
            
            {:reply, response, state}
        end
      
      # Handle active scene resources
      String.starts_with?(uri, "blender://scene/") ->
        case Helpers.parse_scene_uri(uri) do
          {:ok, scene_id} ->
            case Helpers.get_scene_resource(scene_id) do
              {:ok, content} ->
                # Optionally store to AriaStorage for persistence (async)
                # This creates a backup copy of the scene
                Task.start(fn ->
                  Helpers.store_scene_to_aria_storage(scene_id, content)
                end)
                
                id = Map.get(request, "id", nil)
                response = 
                  %{
                    "jsonrpc" => "2.0",
                    "result" => %{
                      "contents" => [
                        %{
                          "uri" => uri,
                          "mimeType" => "application/json",
                          "text" => Jason.encode!(content)
                        }
                      ]
                    }
                  }
                  |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
                
                {:reply, response, state}
              
              {:error, reason} ->
                id = Map.get(request, "id", nil)
                response = 
                  %{
                    "jsonrpc" => "2.0",
                    "error" => %{
                      "code" => -32603,
                      "message" => "Failed to read resource: #{reason}"
                    }
                  }
                  |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
                
                {:reply, response, state}
            end
          
          {:error, reason} ->
            id = Map.get(request, "id", nil)
            response = 
              %{
                "jsonrpc" => "2.0",
                "error" => %{
                  "code" => -32602,
                  "message" => "Invalid resource URI: #{reason}"
                }
              }
              |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
            
            {:reply, response, state}
        end
      
      true ->
        id = Map.get(request, "id", nil)
        response = 
          %{
            "jsonrpc" => "2.0",
            "error" => %{
              "code" => -32602,
              "message" => "Invalid resource URI format"
            }
          }
          |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
        
        {:reply, response, state}
    end
  end
end

