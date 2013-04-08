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

  def create(name, definition // []) do
    :mnesia.create_table(name, definition)
  end

  def info(name, key) do
    :mnesia.table_info(name, key)
  end

  def mode(name, value) do
    :mnesia.change_table_access_mode(name, value)
  end

  def copying(name, node, to) do
    :mnesia.change_table_copy_type(name, node, to)
  end

  def priority(name, value) do
    :mnesia.change_table_load_order(name, value)
  end

  def majority(name, value) do
    :mnesia.change_table_majority(name, value)
  end

  def add_index(name, attribute) do
    :mnesia.add_table_index(name, attribute)
  end

  def delete_index(name, attribute) do
    :mnesia.del_table_index(name, attribute)
  end

  def lock(name, mode) do
    :mnesia.lock({ :table, name }, mode)
  end

  def destroy(name) do
    :mnesia.delete_table(name)
  end

  def clear(name) do
    :mnesia.clear_table(name)
  end

  def keys(name) do
    :mnesia.all_keys(name)
  end

  def keys!(name) do
    :mnesia.dirty_all_keys(name)
  end

  def at!(name, position) do
    :mnesia.dirty_slot(name, position)
  end

  def first(name) do
    :mnesia.first(name)
  end

  def first!(name) do
    :mnesia.dirty_first(name)
  end

  def next(name, key) do
    :mnesia.next(name, key)
  end

  def next!(name, key) do
    :mnesia.dirty_next(name, key)
  end

  def prev(name, key) do
    :mnesia.prev(name, key)
  end

  def prev!(name, key) do
    :mnesia.dirty_prev(name, key)
  end

  def last(name) do
    :mnesia.last(name)
  end

  def last!(name) do
    :mnesia.dirty_last(name)
  end

  def delete(name, key) do
    :mnesia.delete(name, key)
  end

  def delete!(name, key) do
    :mnesia.dirty_delete(name, key)
  end

  def write(name, data, lock // :write) do
    :mnesia.write(name, data, lock)
  end

  def write!(name, data) do
    :mnesia.dirty_write(name, data)
  end

  def read(name, key, lock // :read) do
    :mnesia.read(name, key, lock)
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

  defmacro __using__(_opts) do
    quote do
      import Amnesia.Table
    end
  end

  defmacro deffunctions(opts) do
    indices = if opts[:index] do
      [opts[:index]]
    else
      opts[:indices] || []
    end

    if indices == [1] do
      indices = []
    end

    quote do
      def __options__ do
        unquote(opts)
      end

      def create(copying // []) do
        Amnesia.Table.create(__MODULE__, [
          record_name: __MODULE__,
          attributes:  List.Dict.keys(@record_fields),
          index:       unquote(indices),

          type:          unquote(opts[:type])     || :set,
          access_mode:   unquote(opts[:mode])     || :read_write,
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
        elem self, Enum.at!(unquote(indices), 0)
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
    end
  end
end
