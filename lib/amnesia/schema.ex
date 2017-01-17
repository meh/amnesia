#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Schema do
  @doc """
  Print the schema information.
  """
  @spec print :: :ok
  def print do
    :mnesia.schema
  end

  @doc """
  Print the schema of the given table.
  """
  @spec print(atom) :: :ok
  def print(tab) do
    :mnesia.schema(tab)
  end

  @doc """
  Create the schema on the given nodes.
  """
  @spec create :: :ok | { :error, any }
  @spec create([node]) :: :ok | { :error, any }
  def create(nodes \\ [node()]) do
    :mnesia.create_schema(nodes)
  end

  @doc """
  Destroy the schema on the given nodes.
  """
  @spec destroy :: :ok | { :error, any }
  @spec destroy([node]) :: :ok | { :error, any }
  def destroy(nodes \\ [node()]) do
    :mnesia.delete_schema(nodes)
  end
end
