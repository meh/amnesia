#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table do
  @type cv :: :disk | :disk! | :memory
  @type c  :: [{ cv, [node] }]
  @type o  :: { :atomic, :ok } | { :aborted, any }

  @doc """
  Wait for the passed tables for the given timeout, see `mnesia:wait_for_tables`.
  """
  @spec wait([atom]) :: :ok | { :timeout, [atom] } | { :error, atom }
  @spec wait([atom], integer | :infinity) :: :ok | { :timeout, [atom] } | { :error, atom }
  def wait(names, timeout // :infinity) do
    :mnesia.wait_for_tables(names, timeout)
  end

  @doc """
  Force the loading of the given table, see `mnesia:force_load_table`.
  """
  @spec force(atom) :: :yes | { :error, any }
  def force(name) do
    :mnesia.force_load_table(name)
  end

  @doc """
  Create a table with the given name and definition, see `mnesia:create_table`.
  """
  @spec create(atom) :: o
  @spec create(atom, c) :: o
  def create(name, definition // []) do
    :mnesia.create_table(name, definition)
  end

  @doc """
  Transform a table, useful to change tables in a running instance, see
  `mnesia:transform_table`.
  """
  @spec transform(atom, [atom], function) :: o
  def transform(name, attributes, fun) do
    :mnesia.transform_table(name, fun, attributes)
  end

  @doc """
  Transform a table, renaming it, useful to change tables in a running
  instance, see `mnesia:transform_table`.
  """
  @spec transform(atom, atom, [atom], function) :: o
  def transform(name, new_name, attributes, fun) do
    :mnesia.transform_table(name, fun, attributes, new_name)
  end

  @doc """
  Get information about a given table, see `mnesia:table_info`.
  """
  @spec info(atom, atom) :: any
  def info(name, key) do
    :mnesia.table_info(name, key)
  end

  @doc """
  Return properties of the given table.
  """
  @spec properties(atom) :: Keyword.t
  def properties(name) do
    props = info(name, :all)

    Keywords.new([
      version:     props[:version],
      type:        props[:type],
      mode:        props[:access_mode],
      attributes:  props[:attributes],
      record:      props[:record_name],
      arity:       props[:arity],
      checkpoints: props[:checkpoints],
      cookie:      props[:cookie],
      user:        props[:user_properties],

      storage: case props[:storage_type] do
        :ram_copies       -> :memory
        :disc_copies      -> :disk
        :disc_only_copies -> :disk!
        :unknown          -> :remote
      end,

      master_nodes: props[:master_nodes],

      where: [
        read:  props[:where_to_read],
        write: props[:where_to_write]
      ],

      load: [
        node:   props[:load_node],
        order:  props[:load_order],
        reason: props[:load_reason]
      ],

      copying: [
        memory: props[:ram_copies],
        disk:   props[:disc_copies],
        disk!:  props[:disc_only_copies]
      ],

      size:   props[:size],
      memory: props[:memory]
    ])
  end

  @doc """
  Return the type of the given table.
  """
  @spec type(atom) :: :set | :ordered_set | :bag
  def type(name) do
    info(name, :type)
  end

  @doc """
  Check if the given table is a bag.
  """
  @spec bag?(atom) :: boolean
  def bag?(name) do
    type(name) == :bag
  end

  @doc """
  Check if the given table is a set.
  """
  @spec set?(atom) :: boolean
  def set?(name) do
    type(name) == :set
  end

  @doc """
  Check if the given table is an ordered set.
  """
  @spec ordered_set?(atom) :: boolean
  def ordered_set?(name) do
    type(name) == :ordered_set
  end

  @doc """
  Change the access mode of the given table, see `mnesia:change_table_access_mode`.

  ## Modes

  * `:both` sets read and write mode, it's the default.
  * `:read!` sets read-only mode.
  """
  @spec mode(atom, :both | :read!) :: o
  def mode(name, value) do
    :mnesia.change_table_access_mode(name, case value do
      :both  -> :read_write
      :read! -> :read_only
    end)
  end

  @doc """
  Change the copying mode of the given table on the given node, see
  `mnesia:change_table_copy_type`.

  ## Modes

  * `:disk` sets `:disc_copies` mode
  * `:disk!` sets `:disc_only_copies` mode
  * `:memory` sets `:ram_copies` mode
  """
  @spec copying(atom, node, cv) :: o
  def copying(name, node, to) do
    :mnesia.change_table_copy_type(name, node, case to do
      :disk   -> :disc_copies
      :disk!  -> :disc_only_copies
      :memory -> :ram_copies
    end)
  end

  @doc """
  Change the given table loading priority.
  """
  @spec priority(atom, integer) :: o
  def priority(name, value) do
    :mnesia.change_table_load_order(name, value)
  end

  @doc """
  Change the given table majority, see `mnesia:change_table_majority`.
  """
  @spec majority(atom, boolean) :: o
  def majority(name, value) do
    :mnesia.change_table_majority(name, value)
  end

  @doc """
  Add a copy of the table to the given node with the given mode, see
  `mnesia:add_table_copy`.

  * `:disk` sets `:disc_copies` mode
  * `:disk!` sets `:disc_only_copies` mode
  * `:memory` sets `:ram_copies` mode
  """
  @spec add_copy(atom, node) :: o
  @spec add_copy(atom, node, cv) :: o
  def add_copy(name, node, type // :disk) do
    :mnesia.add_table_copy(name, node, case type do
      :disk   -> :disc_copies
      :disk!  -> :disc_only_copies
      :memory -> :ram_copies
    end)
  end

  @doc """
  Move the copy of the given table from the given node to another given
  node, see `mnesia:move_table_copy`.
  """
  @spec move_copy(atom, node, node) :: o
  def move_copy(name, from, to) do
    :mnesia.move_copy(name, from, to)
  end

  @doc """
  Delete a copy of the table on the given node, see `mnesia:del_table_copy`.
  """
  @spec delete_copy(atom, node) :: o
  def delete_copy(name, node) do
    :mnesia.del_table_copy(name, node)
  end

  @doc """
  Add an index to the given table for the given attribute, see
  `mnesia:add_table_index`.
  """
  @spec add_index(atom, atom) :: o
  def add_index(name, attribute) do
    :mnesia.add_table_index(name, attribute)
  end

  @doc """
  Delete an index on the given table for the given attribute, see
  `mnesia:del_table_index`.
  """
  @spec delete_index(atom, atom) :: o
  def delete_index(name, attribute) do
    :mnesia.del_table_index(name, attribute)
  end

  @doc """
  Set master nodes for the given table, see `mnesia:set_master_nodes`.
  """
  @spec master_nodes(atom, [node]) :: :ok | { :error, any }
  def master_nodes(name, nodes) do
    :mnesia.set_master_nodes(name, nodes)
  end

  @doc """
  Lock the given table for the given kind of lock, see `mnesia:lock`.

  ## Locks

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  * `:read` sets a `:read` lock
  """
  @spec lock(atom, :write | :write! | :read) :: [node] | :ok | no_return
  def lock(name, mode) do
    :mnesia.lock({ :table, name }, case mode do
      :write  -> :write
      :write! -> :sticky_write
      :read   -> :read
    end)
  end

  @doc """
  Destroy the given table, see `mnesia:delete_table`.
  """
  @spec destroy(atom) :: o
  def destroy(name) do
    :mnesia.delete_table(name)
  end

  @doc """
  Clear the given table, see `mnesia:clear_table`.
  """
  @spec clear(atom) :: o
  def clear(name) do
    :mnesia.clear_table(name)
  end

  @doc """
  Read records from the given table with the given key, locking in the given
  mode, see `mnesia:read`.

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  * `:read` sets a `:read` lock
  """
  @spec read(atom, any) :: [record] | no_return
  @spec read(atom, any, :read | :write | :write!) :: [record] | no_return
  def read(name, key, lock // :read) do
    :mnesia.read(name, key, case lock do
      :read   -> :read
      :write  -> :write
      :write! -> :sticky_write
    end)
  end

  @doc """
  Read records from the given table with the given key, see `mnesia:dirty_read`.
  """
  @spec read!(atom, any) :: [record] | no_return
  def read!(name, key) do
    :mnesia.dirty_read(name, key)
  end

  @doc """
  Read records on the given table based on a secondary index given as position,
  see `mnesia:index_read`.
  """
  @spec read_at(atom, any, integer | atom) :: [record] | no_return
  def read_at(name, key, position) do
    :mnesia.index_read(name, key, position)
  end

  @doc """
  Read records on the given table based on a secondary index given as position,
  see `mnesia:dirty_index_read`.
  """
  @spec read_at!(atom, any, integer | atom) :: [record] | no_return
  def read_at!(name, key, position) do
    :mnesia.dirty_index_read(name, key, position)
  end

  @doc """
  Read all keys in the given table, see `mnesia:all_keys`.
  """
  @spec keys(atom) :: list | no_return
  def keys(name) do
    :mnesia.all_keys(name)
  end

  @doc """
  Read all keys in the given table, see `mnesia:dirty_all_keys`.
  """
  @spec keys!(atom) :: list | no_return
  def keys!(name) do
    :mnesia.dirty_all_keys(name)
  end

  @doc """
  Read a slot from the given table, see `mnesia:dirty_slot`.
  """
  @spec at!(atom, integer) :: record | nil | no_return
  def at!(name, position) do
    case :mnesia.dirty_slot(name, position) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the first key in the table, see `mnesia:first`.
  """
  @spec first(atom) :: any | nil | no_return
  def first(name) do
    case :mnesia.first(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the first key in the table, see `mnesia:dirty_read`.
  """
  @spec first!(atom) :: any | nil | no_return
  def first!(name) do
    case :mnesia.dirty_first(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the next key in the table starting from the given key, see `mnesia:next`.
  """
  @spec next(atom, any) :: any | nil | no_return
  def next(name, key) do
    case :mnesia.next(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the next key in the table starting from the given key, see
  `mnesia:dirty_next`.
  """
  @spec next!(atom, any) :: any | nil | no_return
  def next!(name, key) do
    case :mnesia.dirty_next(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the previous key in the table starting from the given key, see
  `mnesia:prev`.
  """
  @spec prev(atom, any) :: any | nil | no_return
  def prev(name, key) do
    case :mnesia.prev(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the previous key in the table starting from the given key, see
  `mnesia:dirty_prev`.
  """
  @spec prev!(atom, any) :: any | nil | no_return
  def prev!(name, key) do
    case :mnesia.dirty_prev(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the last key in the table, see `mnesia:last`.
  """
  @spec last(atom) :: any | nil | no_return
  def last(name) do
    case :mnesia.last(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  @doc """
  Get the last key in the table, see `mnesia:dirty_last`.
  """
  @spec last!(atom) :: any | nil | no_return
  def last!(name) do
    case :mnesia.dirty_last(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  defrecord Selection, values: [], continuation: nil do
    @moduledoc """
    Selection wraps a `mnesia:select` result, which may or may not contain a
    continuation, in case of continuations you can access the next set of
    values by calling `.next`.
    """

    @type t :: Selection[values: [any], continuation: any]

    @doc """
    Get a selection from the various select results.
    """
    @spec from(:"$end_of_table" | list | { list, any }) :: t | nil
    def from(value) do
      case value do
        :"$end_of_table" -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> Selection[values: v, continuation: c]
        [_|_]    -> Selection[values: value]
      end
    end

    @doc """
    Get the next set of values wrapped in another Selection record, returns nil
    if there are no more.
    """
    @spec next(t) :: t | nil | no_return
    def next(Selection[continuation: nil]) do
      nil
    end

    def next(self) do
      from(:mnesia.select(self.continuation))
    end
  end

  @doc """
  Select records in the given table using a match_spec, optionally passing a
  limit to use for each number of returned records and a lock, see
  `mnesia:select`.
  """
  @spec select(atom, any) :: Selection.t | nil | no_return
  @spec select(atom, any, integer) :: Selection.t | nil | no_return
  @spec select(atom, any, integer, :read | :write) :: Selection.t | nil | no_return
  def select(name, spec, limit // nil, lock // :read) do
    if limit do
      Selection.from(:mnesia.select(name, spec, limit, lock))
    else
      Selection.from(:mnesia.select(name, spec, lock))
    end
  end

  @doc """
  Select records in the given table using a match_spec, see
  `mnesia:dirty_select`.
  """
  @spec select!(atom, any) :: Selection.t | nil | no_return
  def select!(name, spec) do
    Selection.from(:mnesia.dirty_select(name, spec))
  end

  @doc """
  Select records in the given table using simple don't care values, see
  `mnesia:match_object`.
  """
  @spec match(atom, any, :read | :write) :: [record] | no_return
  def match(name, pattern, lock // :read) do
    :mnesia.match_object(name, pattern, lock)
  end

  @doc """
  Select records in the given table using simple don't care values, see
  `mnesia:dirty_match_object`.
  """
  @spec match(atom, any) :: [record] | no_return
  def match!(name, pattern) do
    :mnesia.dirty_match_object(name, pattern)
  end

  @doc """
  Fold the whole given table from the left, see `mnesia:foldl`.
  """
  @spec foldl(atom, any, (fun(record, any) -> any)) :: any | no_return
  def foldl(name, acc, fun) do
    :mnesia.foldl(fun, acc, name)
  end

  @doc """
  Fold the whole given table from the right, see `mnesia:foldr`.
  """
  @spec foldl(atom, any, (fun(record, any) -> any)) :: any | no_return
  def foldr(name, acc, fun) do
    :mnesia.foldr(fun, acc, name)
  end

  @doc """
  Return an iterator for the given table to use with Enum functions.
  """
  @spec iterator(atom) :: Amnesia.Table.Iterator.t
  @spec iterator(atom, :read | :write | :write!) :: Amnesia.Table.Iterator.t
  def iterator(name, lock // :read) do
    Amnesia.Table.Iterator[table: name, type: type(name), lock: lock]
  end

  @doc """
  Return an iterator for the given table to use with the Enum functions using
  dirty operations to retrieve information.
  """
  @spec iterator!(atom) :: Amnesia.Table.Iterator.t
  def iterator!(name) do
    Amnesia.Table.Iterator[table: name, type: type(name), dirty: true]
  end

  @doc """
  Return a reverse iterator for the given table to use with the Enum functions.
  """
  @spec reverse_iterator(atom) :: Amnesia.Table.Iterator.t
  @spec reverse_iterator(atom, :read | :write | :write!) :: Amnesia.Table.Iterator.t
  def reverse_iterator(name, lock // :read) do
    Amnesia.Table.Iterator[table: name, type: type(name), lock: lock, reverse: true]
  end

  @doc """
  Return a reverse iterator for the given table to use with the Enum functions
  using dirty operations to retrieve information.
  """
  @spec reverse_iterator!(atom) :: Amnesia.Table.Iterator.t
  def reverse_iterator!(name) do
    Amnesia.Table.Iterator[table: name, type: type(name), dirty: true, reverse: true]
  end

  @doc """
  Delete the given record in the given table, see `mnesia:delete`.

  ## Locks

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  """
  @spec delete(atom, any) :: :ok | no_return
  @spec delete(atom, any, :write | :write!) :: :ok | no_return
  def delete(name, key, lock // :write) do
    :mnesia.delete(name, key, case lock do
      :write  -> :write
      :write! -> :sticky_write
    end)
  end

  @doc """
  Delete the given record in the given table, see `mnesia:dirty_delete`.
  """
  @spec delete!(atom, any) :: :ok | no_return
  def delete!(name, key) do
    :mnesia.dirty_delete(name, key)
  end

  @doc """
  Write the given record in the given table, using the given lock, see
  `mnesia:write`.

  ## Locks

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  """
  @spec write(atom, record) :: :ok | no_return
  @spec write(atom, record, :write | :write!) :: :ok | no_return
  def write(name, data, lock // :write) do
    :mnesia.write(name, data, case lock do
      :write  -> :write
      :write! -> :sticky_write
    end)
  end

  @doc """
  Write the given record in the given table, see `mnesia:dirty_write`.
  """
  @spec write!(atom, record) :: :ok | no_return
  def write!(name, data) do
    :mnesia.dirty_write(name, data)
  end

  @doc false
  def deftable!(name, attributes, opts // []) do
    if length(attributes) <= 1 do
      raise ArgumentError, message: "the table attributes must be more than 1"
    end

    block      = Keyword.get(opts, :do, nil)
    opts       = Keyword.delete(opts, :do)
    definition = Keyword.new

    index = Keyword.get(opts, :index, [])

    unless is_list index do
      index = [index]
    end

    index = Enum.map(index, fn
      a when is_integer a -> a + 1
      a ->
        Enum.find_index(attributes, fn(i) ->
          case i do
            { name, _ } -> a == name
            name        -> a == name
          end
        end) + 1
    end)

    definition = Keyword.put(definition, :index, if index == [1], do: [], else: index)

    definition = Keyword.put(definition, :access_mode, if opts[:mode] do
      case opts[:mode] do
        :both  -> :read_write
        :read! -> :read_only
      end
    else
      :read_write
    end)

    if opts[:type] do
      definition = Keyword.put(definition, :type, opts[:type])
    end

    if opts[:majority] do
      definition = Keyword.put(definition, :majority, opts[:majority])
    end

    if opts[:priority] do
      definition = Keyword.put(definition, :load_order, opts[:priority])
    end

    if opts[:local] do
      definition = Keyword.put(definition, :local_content, opts[:local])
    end

    if opts[:fragmentation] do
      properties = Keyword.new

      if number = opts[:fragmentation][:number] do
        properties = Keyword.put(properties, :n_fragments, number)
      end

      if copying = opts[:fragmentation][:copying] do
        if copying[:memory] do
          properties = Keyword.put(properties, :n_ram_copies, copying[:memory])
        end

        if copying[:disk] do
          properties = Keyword.put(properties, :n_disc_copies, copying[:disk])
        end

        if copying[:disk!] do
          properties = Keyword.put(properties, :n_disc_only_copies, copying[:disk!])
        end
      end

      if nodes = opts[:fragmentation][:nodes] do
        properties = Keyword.put(properties, :node_pool, nodes)
      end

      if foreign = opts[:fragmentation][:foreign] do
        if foreign[:key] do
          properties = Keyword.put(properties, :foreign_key, foreign[:key])
        end
      end

      if hash = opts[:hash] do
        if hash[:module] do
          properties = Keyword.put(properties, :hash_module, hash[:module])
        end

        if hash[:state] do
          properties = Keyword.put(properties, :hash_state, hash[:state])
        end
      end

      definition = Keyword.put(definition, :frag_properties, properties)
    end

    quote do
      defrecord unquote(name), unquote(attributes) do
        @doc false
        def __options__ do
          unquote(opts)
        end

        @doc """
        Wait for the table optionally with a timeout.
        """
        @spec wait :: :ok | { :timeout, [atom] } | { :error, atom }
        @spec wait(integer | :infinity) :: :ok | { :timeout, [atom] } | { :error, atom }
        def wait(timeout // :infinity) do
          Amnesia.Table.wait([__MODULE__], timeout)
        end

        @doc """
        Force load the table.
        """
        @spec force :: :yes | { :error, any }
        def force do
          Amnesia.Table.force(__MODULE__)
        end

        @doc """
        Create the table with the given copying mode.
        """
        @spec create :: { :atomic, :ok } | { :aborted, any }
        @spec create(Amnesia.Table.c) :: { :atomic, :ok } | { :aborted, any }
        def create(copying // []) do
          definition = Keyword.merge(unquote(definition), [
            record_name: __MODULE__,
            attributes:  Keyword.keys(@record_fields)
          ])

          if copying[:memory] do
            definition = Keyword.put(definition, :ram_copies, copying[:memory])
          end

          if copying[:disk] do
            definition = Keyword.put(definition, :disc_copies, copying[:disk])
          end

          if copying[:disk!] do
            definition = Keyword.put(definition, :disc_only_copies, copying[:disk!])
          end

          Amnesia.Table.create(__MODULE__, definition)
        end

        @doc """
        Get the table name from the record.
        """
        @spec table(t) :: atom
        def table(self) do
          elem self, 0
        end

        @doc """
        Return the type of the table.
        """
        @spec type(t) :: :set | :ordered_set | :bag
        def type(self) do
          unquote(opts[:type])
        end

        @doc """
        Check if the table is a bag.
        """
        @spec bag? :: boolean
        def bag? do
          unquote(opts[:type]) == :bag
        end

        @doc """
        Check if the table is a set.
        """
        @spec set? :: boolean
        def set? do
          (unquote(opts[:type]) || :set) == :set
        end

        @doc """
        Check if the table is an ordered set.
        """
        @spec ordered_set? :: boolean
        def ordered_set? do
          unquote(opts[:type]) == :ordered_set
        end

        @doc """
        Get information about the table, see `mnesia:table_info`.
        """
        @spec info(atom) :: any
        def info(key) do
          Amnesia.Table.info(__MODULE__, key)
        end

        @doc """
        Return properties of the table.
        """
        @spec properties :: Keyword.t
        def properties do
          Amnesia.Table.properties(__MODULE__)
        end

        @doc """
        Change the access of the table, see `mnesia:change_table_access_mode`.

        ## Modes

        * `:both` sets read and write mode, it's the default.
        * `:read!` sets read-only mode.
        """
        @spec mode(:both | :read!) :: Amnesia.Table.o
        def mode(value) do
          Amnesia.Table.mode(__MODULE__, value)
        end

        @doc """
        Change the copying mode of the table on the given node, see
        `mnesia:change_table_copy_type`.

        ## Modes

        * `:disk` sets `:disc_copies` mode
        * `:disk!` sets `:disc_only_copies` mode
        * `:memory` sets `:ram_copies` mode
        """
        @spec copying(node, Amnesia.Table.cv) :: Amnesia.Table.o
        def copying(node, to) do
          Amnesia.Table.copying(__MODULE__, node, to)
        end

        @doc """
        Change the table loading priority.
        """
        @spec priority(integer) :: Amnesia.Table.o
        def priority(value) do
          Amnesia.Table.priority(__MODULE__, value)
        end

        @doc """
        Change the table majority.
        """
        @spec majority(boolean) :: Amnesia.Table.o
        def majority(value) do
          Amnesia.Table.majority(__MODULE__, value)
        end

        @doc """
        Add a copy of the table on the given node with the given mode.
        """
        @spec add_copy(node) :: Amnesia.Table.o
        @spec add_copy(node, Amnesia.Table.cv) :: Amnesia.Table.o
        def add_copy(node, type // :disk) do
          Amnesia.Table.add_copy(__MODULE__, node, type)
        end

        @doc """
        Move a copy of the table from the given node to another given node.
        """
        @spec move_copy(node, node) :: Amnesia.Table.o
        def move_copy(from, to) do
          Amnesia.Table.move_copy(__MODULE__, from, to)
        end

        @doc """
        Delete a copy of the table from the given node.
        """
        @spec delete_copy(node) :: Amnesia.Table.o
        def delete_copy(node) do
          Amnesia.Table.delete_copy(__MODULE__, node)
        end

        @doc """
        Add the index in the table for the given attribute.
        """
        @spec add_index(atom) :: Amnesia.Table.o
        def add_index(attribute) do
          Amnesia.Table.add_index(__MODULE__, attribute)
        end

        @doc """
        Delete the index in the table for the given attribute.
        """
        @spec delete_index(atom) :: Amnesia.Table.o
        def delete_index(attribute) do
          Amnesia.Table.delete_index(__MODULE__, attribute)
        end

        @doc """
        Set master nodes for the table, see `mnesia:set_master_nodes`.
        """
        @spec master_nodes([node]) :: :ok | { :error, any }
        def master_nodes(nodes) do
          Amnesia.Table.master_nodes(__MODULE__, nodes)
        end

        @doc """
        Lock the table with the given lock.

        ## Locks

        * `:write` sets a `:write` lock
        * `:write!` sets a `:sticky_write` lock
        * `:read` sets a `:read` lock
        """
        @spec lock(:write | :write! | :read) :: [node] | :ok | no_return
        def lock(mode) do
          Amnesia.Table.lock(__MODULE__, mode)
        end

        @doc """
        Destroy the table.
        """
        @spec destroy :: Amnesia.Table.o
        def destroy do
          Amnesia.Table.destroy(__MODULE__)
        end

        @doc """
        Clear the content of the table.
        """
        @spec clear :: Amnesia.Table.o
        def clear do
          Amnesia.Table.clear(__MODULE__)
        end

        if unquote(opts[:type]) == :bag do
          @doc """
          Read records from the table with the given key and given lock, see
          `mnesia:read`.

          ## Locks

          * `:write` sets a `:write` lock
          * `:write!` sets a `:sticky_write` lock
          * `:read` sets a `:read` lock
          """
          @spec read(any) :: [t] | no_return
          @spec read(any, :read | :write | :write!) :: [t] | no_return
          def read(key, lock // :read) do
            Amnesia.Table.read(__MODULE__, key, lock)
          end

          @doc """
          Read records from the table, see `mnesia:dirty_read`.
          """
          @spec read!(any) :: [t] | no_return
          def read!(key) do
            Amnesia.Table.read!(__MODULE__, key)
          end
        else
          @doc """
          Read a record from the table with the given lock, see `mnesia:read`.

          Unlike `mnesia:read` this returns either the record or nil.

          ## Locks

          * `:write` sets a `:write` lock
          * `:write!` sets a `:sticky_write` lock
          * `:read` sets a `:read` lock
          """
          @spec read(any) :: t | nil | no_return
          @spec read(any, :read | :write | :write!) :: t | nil | no_return
          def read(key, lock // :read) do
            Enum.first(Amnesia.Table.read(__MODULE__, key, lock))
          end

          @doc """
          Read a record from the table, see `mnesia:dirty_read`.

          Unlike `mnesia:dirty_read` this returns either the record or nil.
          """
          @spec read!(any) :: t | nil | no_return
          def read!(key) do
            Enum.first(Amnesia.Table.read!(__MODULE__, key))
          end
        end

        @doc """
        Read records from the table based on a secondary index given as position,
        see `mnesia:index_read`.
        """
        @spec read_at(any, integer | atom) :: [t] | no_return
        def read_at(key, position) when is_integer position do
          Table.read_at(__MODULE__, key, position)
        end

        def read_at(key, position) when is_atom position do
          Table.read_at(__MODULE__, key, 1 + Enum.find_index(Keyword.keys(@record_fields), &1 == position))
        end

        @doc """
        Read records from the table based on a secondary index given as position,
        see `mnesia:dirty_index_read`.
        """
        @spec read_at!(any, integer | atom) :: [t] | no_return
        def read_at!(key, position) when is_integer position do
          Table.read_at!(__MODULE__, key, position)
        end

        def read_at!(key, position) when is_atom position do
          Table.read_at!(__MODULE__, key, 1 + Enum.find_index(Keyword.keys(@record_fields), &1 == position))
        end

        @doc """
        Return all the keys in the table, see `mnesia:all_keys`.
        """
        @spec keys :: list | no_return
        def keys do
          Amnesia.Table.keys(__MODULE__)
        end

        @doc """
        Return all keys in the table, see `mnesia:dirty_all_keys`.
        """
        @spec keys! :: list | no_return
        def keys! do
          Amnesia.Table.keys!(__MODULE__)
        end

        @doc """
        Read a record based on a slot, see `mnesia:dirty_slot`.
        """
        @spec at!(integer) :: t | nil | no_return
        def at!(position) do
          Amnesia.Table.at!(__MODULE__, position)
        end

        @doc """
        Return the key of the record.
        """
        @spec key(t) :: any
        def key(self) do
          elem self, 1
        end

        @doc """
        Return the first key or record in the table, see `mnesia:first`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec first                :: t | nil | no_return
        @spec first(boolean)       :: any | t | nil | no_return
        @spec first(boolean, atom) :: any | t | nil | no_return
        def first(key // false, lock // :read)

        def first(true, lock) do
          Amnesia.Table.first(__MODULE__)
        end

        def first(false, lock) do
          read(Amnesia.Table.first(__MODULE__), lock)
        end

        @doc """
        Return the first key or record in the table, see `mnesia:dirty_first`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec first!          :: any | t | nil | no_return
        @spec first!(boolean) :: any | t | nil | no_return
        def first!(key // false)

        def first!(false) do
          read!(Amnesia.Table.first!(__MODULE__))
        end

        def first!(true) do
          Amnesia.Table.first!(__MODULE__)
        end

        @doc """
        Return the next key or record in the table, see `mnesia:next`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the next record, if you're calling it directly
        on the module it will treat the argument as key to start from and
        return you the next key.
        """
        @spec next(any | t) :: any | t | nil | no_return
        def next(__MODULE__[] = self) do
          read(Amnesia.Table.next(__MODULE__, self.key))
        end

        def next(key) do
          Amnesia.Table.next(__MODULE__, key)
        end

        @doc """
        Return the next key or record in the table, see `mnesia:dirty_next`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the next record, if you're calling it directly
        on the module it will treat the argument as key to start from and
        return you the next key.
        """
        @spec next!(any | t) :: any | t | nil | no_return
        def next!(__MODULE__[] = self) do
          read!(Amnesia.Table.next!(__MODULE__, self.key))
        end

        def next!(key) do
          Amnesia.Table.next!(__MODULE__, key)
        end

        @doc """
        Return the previous key or record in the table, see `mnesia:prev`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the previous record, if you're calling it
        directly on the module it will treat the argument as key to start from
        and return you the previous key.
        """
        @spec prev(any | t) :: any | t | nil | no_return
        def prev(__MODULE__[] = self) do
          read(Amnesia.Table.prev(__MODULE__, self.key))
        end

        def prev(key) do
          Amnesia.Table.prev(__MODULE__, key)
        end

        @doc """
        Return the previous key or record in the table, see `mnesia:dirty_prev`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the previous record, if you're calling it
        directly on the module it will treat the argument as key to start from
        and return you the previous key.
        """
        @spec prev!(any | t) :: any | t | nil | no_return
        def prev!(__MODULE__[] = self) do
          read!(Amnesia.Table.prev!(__MODULE__, self.key))
        end

        def prev!(key) do
          Amnesia.Table.prev!(__MODULE__, key)
        end

        @doc """
        Return the last key or record in the table, see `mnesia:last`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec last                :: t | nil | no_return
        @spec last(boolean)       :: any | t | nil | no_return
        @spec last(boolean, atom) :: any | t | nil | no_return
        def last(key // false, lock // :read)

        def last(true, lock) do
          Amnesia.Table.last(__MODULE__)
        end

        def last (false, lock) do
          read(Amnesia.Table.last(__MODULE__), lock)
        end

        @doc """
        Return the last key or record in the table, see `mnesia:dirty_last`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec last!          :: any | t | nil | no_return
        @spec last!(boolean) :: any | t | nil | no_return
        def last!(key // false)

        def last!(false) do
          read!(Amnesia.Table.last!(__MODULE__))
        end

        def last!(true) do
          Amnesia.Table.last!(__MODULE__)
        end

        @doc """
        Select records in the table using a match_spec, optionally passing a
        limit to use for each number of returned records and a lock, see
        `mnesia:select`.
        """
        @spec select(any) :: Selection.t | nil | no_return
        @spec select(any, integer, :read | :write) :: Selection.t | nil | no_return
        def select(spec, limit // nil, lock // :read) do
          Amnesia.Table.select(__MODULE__, spec, limit, lock)
        end

        @doc """
        Select records in the table using a match_spec, see
        `mnesia:dirty_select`.
        """
        @spec select!(any) :: Selection.t | nil | no_return
        def select!(spec) do
          Amnesia.Table.select!(__MODULE__, spec)
        end

        @doc """
        Select records in the table using simple don't care values, see
        `mnesia:match_object`.
        """
        @spec match(any) :: [t] | no_return
        @spec match(any, :read | :write) :: [t] | no_return
        def match(pattern, lock // :read) do
          Amnesia.Table.match(__MODULE__, pattern, lock)
        end

        @doc """
        Select records in the table using simple don't care values, see
        `mnesia:dirty_match_object`.
        """
        @spec match!(any) :: [t] | no_return
        def match!(pattern) do
          Amnesia.Table.match!(__MODULE__, pattern)
        end

        @doc """
        Fold the whole table from the left, see `mnesia:foldl`.
        """
        @spec foldl(any, (fun(t, any) -> any)) :: any | no_return
        def foldl(acc, fun) do
          Amnesia.Table.foldl(__MODULE__, acc, fun)
        end

        @doc """
        Fold the whole table from the right, see `mnesia:foldr`.
        """
        @spec foldr(any, (fun(t, any) -> any)) :: any | no_return
        def foldr(acc, fun) do
          Amnesia.Table.foldr(__MODULE__, acc, fun)
        end

        @doc """
        Return an iterator to use with Enum functions.
        """
        @spec iterator :: Amnesia.Table.Iterator.t
        @spec iterator(:read | :write | :write!) :: Amnesia.Table.Iterator.t
        def iterator(lock // :read) do
          Amnesia.Table.iterator(__MODULE__, lock)
        end

        @doc """
        Return an iterator to use with the Enum functions using dirty
        operations to retrieve information.
        """
        @spec iterator! :: Amnesia.Table.Iterator.t
        def iterator! do
          Amnesia.Table.iterator!(__MODULE__)
        end

        @doc """
        Return a reverse iterator to use with the Enum functions.
        """
        @spec reverse_iterator :: Amnesia.Table.Iterator.t
        @spec reverse_iterator(:read | :write | :write!) :: Amnesia.Table.Iterator.t
        def reverse_iterator(lock // :read) do
          Amnesia.Table.reverse_iterator(__MODULE__, lock)
        end

        @doc """
        Return a reverse iterator to use with the Enum functions using dirty
        operations to retrieve information.
        """
        @spec reverse_iterator! :: Amnesia.Table.Iterator.t
        def reverse_iterator! do
          Amnesia.Table.reverse_iterator!(__MODULE__)
        end

        @doc """
        Delete the record or the given key from the table, see `mnesia:delete`
        and `mnesia:delete_object`.
        """
        @spec delete(any | t) :: :ok | no_return
        def delete(__MODULE__[] = self) do
          delete(:write, self)
        end

        def delete(key) do
          delete(key, :write)
        end

        @doc """
        Delete the record or the given key from the table with the given lock,
        see `mnesia:delete` and `mnesia:delete_object`.

        ## Locks

        * `:write` sets a `:write` lock
        * `:write!` sets a `:sticky_write` lock
        """
        @spec delete(atom | any, t | atom) :: :ok | no_return
        def delete(lock, __MODULE__[] = self) do
          :mnesia.delete_object(__MODULE__, self, case lock do
            :write  -> :write
            :write! -> :sticky_write
          end)
        end

        def delete(key, lock) do
          :mnesia.delete(__MODULE__, key, case lock do
            :write  -> :write
            :write! -> :sticky_write
          end)
        end

        @doc """
        Delete the record or the given key from the table, see
        `mnesia:dirty_delete` and `mnesia:dirty_delete_object`.
        """
        @spec delete!(t | any) :: :ok | no_return
        def delete!(__MODULE__[] = self) do
          :mnesia.dirty_delete_object(__MODULE__, self)
        end

        def delete!(key) do
          Amnesia.Table.delete!(__MODULE__, key)
        end

        @doc """
        Write the record to the table, see `mnesia:write`.
        """
        @spec write(t) :: :ok | no_return
        def write(self) do
          :mnesia.write(self)
        end

        @doc """
        Write the record to the table, see `mnesia:dirty_write`.
        """
        @spec write!(t) :: :ok | no_return
        def write!(self) do
          :mnesia.dirty_write(self)
        end

        unquote(block)
      end
    end
  end
end
