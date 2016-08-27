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
  @type o  :: :ok | { :error, any }

  alias Amnesia.Selection
  alias Amnesia.Table.Select
  alias Amnesia.Table.Match
  alias Amnesia.Helper.Options

  @doc """
  Wait for the passed tables for the given timeout, see `mnesia:wait_for_tables`.
  """
  @spec wait([atom]) :: :ok | { :timeout, [atom] } | { :error, atom }
  @spec wait([atom], integer | :infinity) :: :ok | { :timeout, [atom] } | { :error, atom }
  def wait(names, timeout \\ :infinity) do
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
  Checks if a table exists or not.
  """
  @spec exists?(atom) :: boolean
  def exists?(name) do
    :mnesia.system_info(:tables) |> Enum.member?(name)
  end

  @doc """
  Create a table with the given name and definition, see `mnesia:create_table`.

  The definition is a keyword list of options which have a correspondence with
  `mnesia` options, to know what they do check the `mnesia` documentation.

  * `:record` => `:record_name`
  * `:attributes`

  * `:mode` => `:access_mode`
    + `:both`  => `:read_write`
    + `:read!` => `:read_only`

  * `:type`
  * `:index`
  * `:majority`
  * `:priority` => `:load_order`
  * `:user`     => `:user_properties`
  * `:local`    => `:local_content`

  * `:copying` _(a keyword list composed of)_
    + `:memory` => `:ram_copies`
    + `:disk`   => `:disc_copies`
    + `:disk!`  => `:disc_only_copies`

  * `:fragmentation` => `:frag_properties` _(a keyword list composed of)_
    + `:number`  => `:n_fragments`
    + `:nodes`   => `:node_pool`
    + `:foreign` => `:foreign_key`

    + `:hash` _(a keyword list composed of)_
      + `:module` => `:hash_module`
      + `:state`  => `:hash_state`

    + `:copying` _(a keyword list composed of)_
      - `:memory` => `:n_ram_copies`
      - `:disk`   => `:n_disc_copies`
      - `:disk!`  => `:n_disc_only_copies`
  """
  @spec create(atom) :: o
  @spec create(atom, c) :: o
  def create(name, definition \\ []) do
    args = Keyword.new
      |> Options.update(:record_name,      Keyword.get(definition, :record, name))
      |> Options.update(:attributes,       definition[:attributes])
      |> Options.update(:type,             definition[:type])
      |> Options.update(:index,            definition[:index])
      |> Options.update(:majority,         definition[:majority])
      |> Options.update(:load_order,       definition[:priority])
      |> Options.update(:user_properties,  definition[:user])
      |> Options.update(:local_content,    definition[:local])
      |> Options.update(:ram_copies,       definition[:copying][:memory])
      |> Options.update(:disc_copies,      definition[:copying][:disk])
      |> Options.update(:disc_only_copies, definition[:copying][:disk!])

    args = if fragmentation = definition[:fragmentation] do
      properties = Keyword.new
        |> Options.update(:n_fragments,         fragmentation[:number])
        |> Options.update(:node_pool,           fragmentation[:nodes])
        |> Options.update(:n_ram_copies,        fragmentation[:copying][:memory])
        |> Options.update(:n_disc_copies,       fragmentation[:copying][:disk])
        |> Options.update(:n_disc_only_copies,  fragmentation[:copying][:disk!])
        |> Options.update(:foreign_key,         fragmentation[:foreign][:key])
        |> Options.update(:hash_module,         fragmentation[:hash][:module])
        |> Options.update(:hash_state,          fragmentation[:hash][:state])

      Keyword.put(args, :frag_properties, properties)
    else
      args
    end

    args = Options.update(args, :access_mode,
      if mode = definition[:mode] || :both do
        case mode do
          :both  -> :read_write
          :read! -> :read_only
        end
      end)

    :mnesia.create_table(name, args) |> result
  end

  @doc """
  Create a table with the given name and definition, see `mnesia:create_table`,
  raises in case of error.
  """
  @spec create!(atom) :: :ok | no_return
  @spec create!(atom, c) :: :ok | no_return
  def create!(name, definition \\ []) do
    case create(name, definition) do
      :ok ->
        :ok

      { :error, { :already_exists, _ } } ->
        raise Amnesia.TableExistsError, name: name
    end
  end

  @doc """
  Transform a table, useful to change tables in a running instance, see
  `mnesia:transform_table`.
  """
  @spec transform(atom, [atom]) :: o
  def transform(name, attributes) do
    :mnesia.transform_table(name, :ignore, attributes) |> result
  end

  @doc """
  Transform a table, useful to change tables in a running instance, see
  `mnesia:transform_table`.
  """
  @spec transform(atom, [atom] | atom, (tuple -> tuple) | [atom]) :: o
  def transform(name, attributes, fun) when is_function(fun) do
    :mnesia.transform_table(name, fun, attributes) |> result
  end

  def transform(name, new_name, attributes) do
    :mnesia.transform_table(name, :ignore, attributes, new_name) |> result
  end

  @doc """
  Transform a table, renaming it, useful to change tables in a running
  instance, see `mnesia:transform_table`.
  """
  @spec transform(atom, atom, [atom], (tuple -> tuple)) :: o
  def transform(name, new_name, attributes, fun) do
    :mnesia.transform_table(name, fun, attributes, new_name) |> result
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

    [ version:     props[:version],
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
      memory: props[:memory] ]
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
    end) |> result
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
    end) |> result
  end

  @doc """
  Change the given table loading priority.
  """
  @spec priority(atom, integer) :: o
  def priority(name, value) do
    :mnesia.change_table_load_order(name, value) |> result
  end

  @doc """
  Change the given table majority, see `mnesia:change_table_majority`.
  """
  @spec majority(atom, boolean) :: o
  def majority(name, value) do
    :mnesia.change_table_majority(name, value) |> result
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
  def add_copy(name, node, type \\ :disk) do
    :mnesia.add_table_copy(name, node, case type do
      :disk   -> :disc_copies
      :disk!  -> :disc_only_copies
      :memory -> :ram_copies
    end) |> result
  end

  @doc """
  Move the copy of the given table from the given node to another given
  node, see `mnesia:move_table_copy`.
  """
  @spec move_copy(atom, node, node) :: o
  def move_copy(name, from, to) do
    :mnesia.move_table_copy(name, from, to) |> result
  end

  @doc """
  Delete a copy of the table on the given node, see `mnesia:del_table_copy`.
  """
  @spec delete_copy(atom, node) :: o
  def delete_copy(name, node) do
    :mnesia.del_table_copy(name, node) |> result
  end

  @doc """
  Add an index to the given table for the given attribute, see
  `mnesia:add_table_index`.
  """
  @spec add_index(atom, atom) :: o
  def add_index(name, attribute) do
    :mnesia.add_table_index(name, attribute) |> result
  end

  @doc """
  Delete an index on the given table for the given attribute, see
  `mnesia:del_table_index`.
  """
  @spec delete_index(atom, atom) :: o
  def delete_index(name, attribute) do
    :mnesia.del_table_index(name, attribute) |> result
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
    :mnesia.delete_table(name) |> result
  end

  @doc """
  Destroy the given table, see `mnesia:delete_table`, raising in case of error.
  """
  @spec destroy!(atom) :: :ok | no_return
  def destroy!(name) do
    case :mnesia.delete_table(name) do
      { :atomic, :ok } ->
        :ok

      { :aborted, { :no_exists, _ } } ->
        raise Amnesia.TableMissingError, name: name
    end
  end

  @doc """
  Clear the given table, see `mnesia:clear_table`.
  """
  @spec clear(atom) :: o
  def clear(name) do
    :mnesia.clear_table(name) |> result
  end

  @doc """
  Check if the key is present in the given table.
  """
  @spec member?(atom, any) :: boolean
  def member?(name, key) do
    case :mnesia.dirty_read(name, key) do
      [] -> false
      _  -> true
    end
  end

  @doc """
  Get the number of records in the given table.
  """
  @spec count(atom) :: non_neg_integer
  def count(name) do
    info(name, :size)
  end

  @doc """
  Read records from the given table with the given key, locking in the given
  mode, see `mnesia:read`.

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  * `:read` sets a `:read` lock
  """
  @spec read(atom, any) :: [tuple] | no_return
  @spec read(atom, any, :read | :write | :write!) :: [tuple] | nil | no_return
  def read(name, key, lock \\ :read) do
    case :mnesia.read(name, key, case lock do
      :read   -> :read
      :write  -> :write
      :write! -> :sticky_write
    end) do
      [] -> nil
      r  -> r
    end
  end

  @doc """
  Read records from the given table with the given key, see `mnesia:dirty_read`.
  """
  @spec read!(atom, any) :: [tuple] | nil | no_return
  def read!(name, key) do
    case :mnesia.dirty_read(name, key) do
      [] -> nil
      r  -> r
    end
  end

  @doc """
  Read records on the given table based on a secondary index given as position,
  see `mnesia:index_read`.
  """
  @spec read_at(atom, any, integer | atom) :: [tuple] | nil | no_return
  def read_at(name, key, position) do
    case :mnesia.index_read(name, key, position) do
      [] -> nil
      r  -> r
    end
  end

  @doc """
  Read records on the given table based on a secondary index given as position,
  see `mnesia:dirty_index_read`.
  """
  @spec read_at!(atom, any, integer | atom) :: [tuple] | nil | no_return
  def read_at!(name, key, position) do
    case :mnesia.dirty_index_read(name, key, position) do
      [] -> nil
      r  -> r
    end
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
  @spec at!(atom, integer) :: tuple | nil | no_return
  def at!(name, position) do
    case :mnesia.dirty_slot(name, position) do
      :'$end_of_table' -> nil
      value            -> value
    end
  end

  @doc """
  Get the first key in the table, see `mnesia:first`.
  """
  @spec first(atom) :: any | nil | no_return
  def first(name) do
    case :mnesia.first(name) do
      :'$end_of_table' -> nil
      value            -> value
    end
  end

  @doc """
  Get the first key in the table, see `mnesia:dirty_read`.
  """
  @spec first!(atom) :: any | nil | no_return
  def first!(name) do
    case :mnesia.dirty_first(name) do
      :'$end_of_table' -> nil
      value            -> value
    end
  end

  @doc """
  Get the next key in the table starting from the given key, see `mnesia:next`.
  """
  @spec next(atom, any) :: any | nil | no_return
  def next(name, key) do
    case :mnesia.next(name, key) do
      :'$end_of_table' -> nil
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
      :'$end_of_table' -> nil
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
      :'$end_of_table' -> nil
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
      :'$end_of_table' -> nil
      value            -> value
    end
  end

  @doc """
  Get the last key in the table, see `mnesia:last`.
  """
  @spec last(atom) :: any | nil | no_return
  def last(name) do
    case :mnesia.last(name) do
      :'$end_of_table' -> nil
      value            -> value
    end
  end

  @doc """
  Get the last key in the table, see `mnesia:dirty_last`.
  """
  @spec last!(atom) :: any | nil | no_return
  def last!(name) do
    case :mnesia.dirty_last(name) do
      :'$end_of_table' -> nil
      value            -> value
    end
  end

  @doc """
  Select records in the given table using a match_spec, see `mnesia:select`.
  """
  @spec select(atom, any) :: Selection.t | nil | no_return
  def select(name, spec) do
    Select.new(:mnesia.select(name, spec))
  end

  @doc """
  Select records in the given table using a match_spec passing a limit or a
  lock kind, see `mnesia:select`.
  """
  @spec select(atom, integer | :read | :write, any) :: Selection.t | nil | no_return
  def select(name, limit, spec) when is_integer limit do
    Select.new(:mnesia.select(name, spec, limit, :read))
  end

  def select(name, lock, spec) when lock in [:read, :write] do
    Select.new(:mnesia.select(name, spec, lock))
  end

  @doc """
  Select records in the given table using a match_spec passing a limit and a
  lock kind, see `mnesia:select`.
  """
  @spec select(atom, integer | :read | :write, integer | :read | :write, integer) :: Selection.t | nil | no_return
  def select(name, lock, limit, spec) when lock in [:read, :write] and is_integer limit do
    Select.new(:mnesia.select(name, spec, limit, lock))
  end

  def select(name, limit, lock, spec) when lock in [:read, :write] and is_integer limit do
    Select.new(:mnesia.select(name, spec, limit, lock))
  end

  @doc """
  Select records in the given table using a match_spec, see
  `mnesia:dirty_select`.
  """
  @spec select!(atom, any) :: Selection.t | nil | no_return
  def select!(name, spec) do
    Select.new(:mnesia.dirty_select(name, spec))
  end

  @doc """
  Select records in the given table using simple don't care values, see
  `mnesia:match_object`.
  """
  @spec match(atom, :read | :write, any) :: [tuple] | nil | no_return
  def match(name, lock \\ :read, pattern) do
    Match.new(:mnesia.match_object(name, pattern, lock))
  end

  @doc """
  Select records in the given table using simple don't care values, see
  `mnesia:dirty_match_object`.
  """
  @spec match(atom, any) :: [tuple] | nil | no_return
  def match!(name, pattern) do
    Match.new(:mnesia.dirty_match_object(name, pattern))
  end

  @doc """
  Fold the whole given table from the left, see `mnesia:foldl`.
  """
  @spec foldl(atom, any, (tuple, any -> any)) :: any | no_return
  def foldl(name, acc, fun) do
    :mnesia.foldl(fun, acc, name)
  end

  @doc """
  Fold the whole given table from the right, see `mnesia:foldr`.
  """
  @spec foldl(atom, any, (tuple, any -> any)) :: any | no_return
  def foldr(name, acc, fun) do
    :mnesia.foldr(fun, acc, name)
  end

  def stream(name, lock \\ :read) do
    Amnesia.Table.Stream.new(name, type(name), lock: lock)
  end

  def stream!(name) do
    Amnesia.Table.Stream.new(name, type(name), dirty: true)
  end

  @doc """
  Delete the given record in the given table, see `mnesia:delete`.

  ## Locks

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  """
  @spec delete(atom, any) :: :ok | no_return
  @spec delete(atom, any, :write | :write!) :: :ok | no_return
  def delete(name, key, lock \\ :write) do
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
  @spec write(atom, tuple) :: :ok | no_return
  @spec write(atom, tuple, :write | :write!) :: :ok | no_return
  def write(name, data, lock \\ :write) do
    :mnesia.write(name, data, case lock do
      :write  -> :write
      :write! -> :sticky_write
    end)
  end

  @doc """
  Write the given record in the given table, see `mnesia:dirty_write`.
  """
  @spec write!(atom, tuple) :: :ok | no_return
  def write!(name, data) do
    :mnesia.dirty_write(name, data)
  end

  @doc false
  def result({ :atomic, :ok }) do
    :ok
  end

  def result({ :aborted, reason }) do
    { :error, reason }
  end
end
