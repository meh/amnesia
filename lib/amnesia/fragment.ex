#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Fragment do
  use Amnesia.Access, module: :mnesia_frag

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

  @doc """
  Get the fragment properties of the given table.
  """
  @spec properties(atom) :: Keyword.t
  def properties(name) do
    async do
      props = :mnesia.table_info(name, :frag_properties)

      Keyword.new([
        number: :mnesia.table_info(name, :n_fragments),
        nodes:  :mnesia.table_info(name, :node_pool),

        copying: [
          memory: :mnesia.table_info(name, :n_ram_copies),
          disk:   :mnesia.table_info(name, :n_disc_copies),
          disk!:  :mnesia.table_info(name, :n_disc_only_copies)
        ],

        foreign: [
          key: case props[:foreign_key] do
            :undefined -> nil
            key        -> key
          end,

          tables: :mnesia.table_info(name, :foreigners)
        ],

        names:  :mnesia.table_info(name, :frag_names),
        dist:   :mnesia.table_info(name, :frag_dist),
        size:   :mnesia.table_info(name, :frag_size),
        memory: :mnesia.table_info(name, :frag_memory),

        hash: [
          module: props[:hash_module],
          state:  props[:hash_state]
        ]
      ])
    end
  end
end
