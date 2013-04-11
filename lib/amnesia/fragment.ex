#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Fragment do
  @doc """
  Get the fragment properties of the given table.
  """
  @spec properties(atom) :: Keyword.t
  def properties(atom) do
    result     = Keyword.new
    properties = :mnesia.table_info(atom, :frag_properties)

    if number = properties[:n_fragments] do
      result = Keyword.put(result, :number, number)
    end

    if nodes = properties[:node_pool]
      result = Keyword.put(result, :nodes, nodes)
    end

    if (key = properties[:foreign_key]) != :undefined do
      result = Keyword.put(result, :key, key)
    end

    if size = properties[:size] do
      result = Keyword.put(result, :size, size)
    end

    if memory = properties[:memory] do
      result = Keyword.put(result, :memory, memory)
    end

    result
  end

  @doc """
  Activate fragmentation on the given table, see `mnesia:change_table_frag`.
  """
  @spec activate(atom) :: Amnesia.Table.o
  def activate(name) do
    :mnesia.change_table_frag(name, { :activate, [] })
  end

  @doc """
  Activate fragmentation on the given tables on the given nodes, see
  `mnesia:change_table_frag`.
  """
  @spec activate(atom, [node]) :: Amnesia.Table.o
  def activate(name, nodes) do
    :mnesia.change_table_frag(name, { :activate, [node_pool: nodes] })
  end

  @doc """
  Deactivate fragmentation on the table, see `mnesia:change_table_frag`.
  """
  @spec deactivate(atom) :: Amnesia.Table.o
  def deactivate(name) do
    :mnesia.change_table_frag(name, :deactivate)
  end

  @doc """
  Add a fragment to the table on the given nodes, see
  `mnesia:change_table_frag`.
  """
  @spec add(atom, [node]) :: Amnesia.Table.o
  def add(name, nodes) do
    :mnesia.change_table_frag(name, { :add_frag, nodes })
  end

  @doc """
  Delete all fragments from the given table, see `mnesia:change_table_frag`.
  """
  @spec delete(atom) :: Amnesia.Table.o
  def delete(name) do
    :mnesia.change_table_frag(name, :del_frag)
  end

  @doc """
  Add a given node to the fragments of the given table, see
  `mnesia:change_table_frag`.
  """
  @spec add_node(atom, node) :: Amnesia.Table.o
  def add_node(name, node) do
    :mnesia.change_table_frag(name, { :add_node, node })
  end

  @doc """
  Delete a given node to the fragments of the given table, see
  `mnesia:change_table_frag`.
  """
  @spec delete_node(atom, node) :: Amnesia.Table.o
  def delete_node(name, node) do
    :mnesia.change_table_frag(name, { :del_node, node })
  end
end
