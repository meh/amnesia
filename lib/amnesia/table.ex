#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table do
  def wait(names, timeout // :infinity) do
    :mnesia.wait_for_tables(names, timeout)
  end

  def force(name) do
    :mnesia.force_load_table(name)
  end

  def create(name, definition // []) do
    :mnesia.create_table(name, definition)
  end

  def transform(name, attributes, fun) do
    :mnesia.transform_table(name, fun, attributes)
  end

  def transform(name, new_name, attributes, fun) do
    :mnesia.transform_table(name, fun, attributes, new_name)
  end

  def info(name, key) do
    :mnesia.table_info(name, key)
  end

  def mode(name, value) do
    :mnesia.change_table_access_mode(name, case value do
      :both  -> :read_write
      :read! -> :read_only
    end)
  end

  def copying(name, node, to) do
    :mnesia.change_table_copy_type(name, node, case to do
      :disc  -> :disc_copies
      :disc! -> :disc_only_copies

      :disk  -> :disc_copies
      :disk! -> :disc_only_copies

      :ram    -> :ram_copies
      :memory -> :ram_copies
    end)
  end

  def priority(name, value) do
    :mnesia.change_table_load_order(name, value)
  end

  def majority(name, value) do
    :mnesia.change_table_majority(name, value)
  end

  def add_copy(name, node, type // :disk) do
    :mnesia.add_table_copy(name, node, case type do
      :disc  -> :disc_copies
      :disc! -> :disc_only_copies

      :disk  -> :disc_copies
      :disk! -> :disc_only_copies

      :ram    -> :ram_copies
      :memory -> :ram_copies
    end)
  end

  def delete_copy(name, node) do
    :mnesia.del_table_copy(name, node)
  end

  def add_index(name, attribute) do
    :mnesia.add_table_index(name, attribute)
  end

  def delete_index(name, attribute) do
    :mnesia.del_table_index(name, attribute)
  end

  def lock(name, mode) do
    :mnesia.lock({ :table, name }, case mode do
      :write  -> :write
      :write! -> :sticky_write
      :read   -> :read
    end)
  end

  def destroy(name) do
    :mnesia.delete_table(name)
  end

  def clear(name) do
    :mnesia.clear_table(name)
  end

  def read(name, key, lock // :read) do
    :mnesia.read(name, key, case lock do
      :read   -> :read
      :write  -> :write
      :write! -> :sticky_write
    end)
  end

  def read!(name, key) do
    :mnesia.dirty_read(name, key)
  end

  def read_at(name, key, position) do
    :mnesia.index_read(name, key, position)
  end

  def read_at!(name, key, position) do
    :mnesia.dirty_index_read(name, key, position)
  end

  def keys(name) do
    :mnesia.all_keys(name)
  end

  def keys!(name) do
    :mnesia.dirty_all_keys(name)
  end

  def at!(name, position) do
    case :mnesia.dirty_slot(name, position) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def first(name) do
    case :mnesia.first(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def first!(name) do
    case :mnesia.dirty_first(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def next(name, key) do
    case :mnesia.next(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def next!(name, key) do
    case :mnesia.dirty_next(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def prev(name, key) do
    case :mnesia.prev(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def prev!(name, key) do
    case :mnesia.dirty_prev(name, key) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def last(name) do
    case :mnesia.last(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  def last!(name) do
    case :mnesia.dirty_last(name) do
      :"$end_of_table" -> nil
      value            -> value
    end
  end

  defrecord Selection, values: [], continuation: nil do
    def from(value) do
      case value do
        :"$end_of_table" -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> __MODULE__[values: v, continuation: c]
        [_|_]    -> __MODULE__[values: value]
      end
    end

    def next(__MODULE__[continuation: nil]) do
      nil
    end

    def next(self) do
      from(:mnesia.select(self.continuation))
    end
  end

  def select(name, spec, limit // nil, lock // :read) do
    if limit do
      Selection.from(:mnesia.select(name, spec, limit, lock))
    else
      Selection.from(:mnesia.select(name, spec, lock))
    end
  end

  def select!(name, spec) do
    Selection.from(:mnesia.dirty_select(name, spec))
  end

  def match(name, pattern, lock // :read) do
    :mnesia.match_object(name, pattern, lock)
  end

  def match!(name, pattern) do
    :mnesia.dirty_match_object(name, pattern)
  end

  def foldl(name, acc, fun) do
    :mnesia.foldl(fun, acc, name)
  end

  def foldr(name, acc, fun) do
    :mnesia.foldr(fun, acc, name)
  end

  def delete(name, key) do
    :mnesia.delete(name, key)
  end

  def delete!(name, key) do
    :mnesia.dirty_delete(name, key)
  end

  def write(name, data, lock // :write) do
    :mnesia.write(name, data, case lock do
      :write  -> :write
      :write! -> :sticky_write
    end)
  end

  def write!(name, data) do
    :mnesia.dirty_write(name, data)
  end

  defmacro __using__(_opts) do
    quote do
      import Amnesia.Table
    end
  end

  def deftable!(name, attributes, opts // [], do_block // []) do
    if length(attributes) <= 1 do
      raise ArgumentError, message: "the table attributes must be more than 1"
    end

    if opts[:do] do
      { opts, do_block } = { do_block, opts }
    end

    indices = if opts[:index] do
      [opts[:index]]
    else
      opts[:indices] || []
    end

    if indices == [1] do
      indices = []
    end

    mode = if opts[:mode] do
      case opts[:mode] do
        :both  -> :read_write
        :read! -> :read_only
      end
    else
      :read_write
    end

    quote do
      defrecord unquote(name), unquote(attributes) do
        use Amnesia.Table

        def __options__ do
          unquote(opts)
        end

        def wait(timeout // :infinity) do
          Amnesia.Table.wait([__MODULE__], timeout)
        end

        def force do
          Amnesia.Table.force(__MODULE__)
        end

        def create(copying // []) do
          Amnesia.Table.create(__MODULE__, [
            record_name: __MODULE__,
            attributes:  List.Dict.keys(@record_fields),
            index:       unquote(indices),

            access_mode:   unquote(mode),
            type:          unquote(opts[:type])     || :set,
            majority:      unquote(opts[:majority]) || false,
            load_order:    unquote(opts[:priority]) || 0,
            local_content: unquote(opts[:local])    || false
          ])
        end

        def bag? do
          unquote(opts[:type]) == :bag
        end

        def set? do
          unquote(opts[:type]) == :set
        end

        def ordered_set? do
          unquote(opts[:type]) == :ordered_set
        end

        def info(key) do
          Amnesia.Table.info(__MODULE__, key)
        end

        def mode(value) do
          Amnesia.Table.mode(__MODULE__, value)
        end

        def copying(node, to) do
          Amnesia.Table.copying(__MODULE__, node, to)
        end

        def priority(value) do
          Amnesia.Table.priority(__MODULE__, value)
        end

        def majority(value) do
          Amnesia.Table.majority(__MODULE__, value)
        end

        def add_copy(node, type // :disk) do
          Amnesia.Table.add_copy(__MODULE__, node, type)
        end

        def delete_copy(node) do
          Amnesia.Table.delete_copy(__MODULE__, node)
        end

        def add_index(attribute) do
          Amnesia.Table.add_index(__MODULE__, attribute)
        end

        def delete_index(attribute) do
          Amnesia.Table.delete_index(__MODULE__, attribute)
        end

        def lock(mode) do
          Amnesia.Table.lock(__MODULE__, mode)
        end

        def destroy do
          Amnesia.Table.destroy(__MODULE__)
        end

        def clear do
          Amnesia.Table.clear(__MODULE__)
        end

        if unquote(opts[:type]) == :bag do
          def read(key, lock // :read) do
            Amnesia.Table.read(__MODULE__, key, lock)
          end

          def read!(key) do
            Amnesia.Table.read!(__MODULE__, key)
          end
        else
          def read(key, lock // :read) do
            Enum.first(Amnesia.Table.read(__MODULE__, key, lock))
          end

          def read!(key) do
            Enum.first(Amnesia.Table.read!(__MODULE__, key))
          end
        end

        def read_at(key, position) when is_integer position do
          Table.read_at(__MODULE__, key, position)
        end

        def read_at(key, position) when is_atom position do
          Table.read_at(__MODULE__, key, 1 + Enum.find_index(List.Dict.keys(@record_fields), &1 == position))
        end

        def read_at!(key, position) when is_integer position do
          Table.read_at!(__MODULE__, key, position)
        end

        def read_at!(key, position) when is_atom position do
          Table.read_at!(__MODULE__, key, 1 + Enum.find_index(List.Dict.keys(@record_fields), &1 == position))
        end

        def keys do
          Amnesia.Table.keys(__MODULE__)
        end

        def keys! do
          Amnesia.Table.keys!(__MODULE__)
        end

        def at!(position) do
          Amnesia.Table.at!(__MODULE__, position)
        end

        def first do
          Amnesia.Table.first(__MODULE__)
        end

        def first! do
          Amnesia.Table.first!(__MODULE__)
        end

        def key(self) do
          elem self, Enum.at!(unquote(indices), 0) || 1
        end

        def next(self) do
          Amnesia.Table.next(__MODULE__, self.key)
        end

        def next!(self) do
          Amnesia.Table.next!(__MODULE__, self.key)
        end

        def prev(self) do
          Amnesia.Table.prev(__MODULE__, self.key)
        end

        def prev!(self) do
          Amnesia.Table.prev!(__MODULE__, self.key)
        end

        def last do
          Amnesia.Table.last(__MODULE__)
        end

        def last! do
          Amnesia.Table.last!(__MODULE__)
        end

        def select(spec, limit // nil, lock // :read) do
          Amnesia.Table.select(__MODULE__, spec, limit, lock)
        end

        def select!(spec) do
          Amnesia.Table.select!(__MODULE__, spec)
        end

        def match(pattern, lock // :read) do
          Amnesia.Table.match(__MODULE__, pattern, lock)
        end

        def match!(pattern) do
          Amnesia.Table.match!(__MODULE__, pattern)
        end

        def foldl(acc, fun) do
          Amnesia.Table.foldl(__MODULE__, acc, fun)
        end

        def foldr(acc, fun) do
          Amnesia.Table.foldr(__MODULE__, acc, fun)
        end

        def delete(self) do
          :mnesia.delete_object(self)
        end

        def delete!(self) do
          :mnesia.dirty_delete_object(self)
        end

        def delete(key, self) do
          Amnesia.Table.delete(__MODULE__, key)
        end

        def delete!(key, self) do
          Amnesia.Table.delete!(__MODULE__, key)
        end

        def write(self) do
          :mnesia.write(self)
        end

        def write!(self) do
          :mnesia.dirty_write(self)
        end

        unquote(do_block)
      end

      @tables unquote(name)
    end
  end
end
