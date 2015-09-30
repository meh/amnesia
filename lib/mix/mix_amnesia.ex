defmodule Mix.Amnesia do

  @moduledoc false

  @doc """
  Given an atom, checks whether it is a module created with 
  `Amnesia.defdatabase/2`.
  """
  @spec ensure_database_module(binary) :: atom
  def ensure_database_module(database) when is_binary(database) do
    module = Module.concat([database])

    # inspired in Mix.Ecto
    Mix.Task.run "loadpaths", []
    Mix.Task.run "compile", []

    case Code.ensure_compiled(module) do
      {:module, _} ->
        if function_exported?(module, :metadata, 0) do

          unless %Amnesia.Metadata{database: module} == module.metadata do
            Mix.raise "module #{module} is not an Amnesia.Database. " <>
                      "Please pass a proper database with the --database option."
          end

          module
          
        else
          Mix.raise "module #{inspect module} is not an Amnesia.Database. " <>
                    "Please pass a proper database with the --database option."
        end
      {:error, error} ->
        Mix.raise "could not load #{inspect module}, error: #{inspect error}. " <>
                  "Please pass a proper database with the --database option."
    end
  end
  
end
