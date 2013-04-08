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

  def majority(name, value) do
    :mnesia.change_table_majority(name, value)
  end

  def priority(name, value) do
    :mnesia.change_table_load_order(name, value)
  end

  def copying(name, node, to) do
    :mnesia.change_table_copy_type(name, node, to)
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

  defmacro __using__(_opts) do
    quote do
      import Amnesia.Table
    end
  end

  defmacro deffunctions(name, opts) do
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

      def create(copying // [node]) do
        Table.create(unquote(name), [
          record_name: unquote(name),
          attributes:  List.Dict.keys(@record_fields),
          index:       unquote(indices),

          type:        unquote(opts[:type])     || :set,
          access_mode: unquote(opts[:mode])     || :read_write,
          majority:    unquote(opts[:majority]) || false,
          load_order:  unquote(opts[:priority]) || 0
        ])
      end

      def info(key) do
        Table.info(unquote(name), key)
      end

      def mode(value) do
        Table.mode(unquote(name), value)
      end

      def majority(value) do
        Table.majority(unquote(name), value)
      end

      def priority(value) do
        Table.priority(unquote(name), value)
      end

      def copying(node, to) do
        Table.copying(unquote(name), node, to)
      end

      def lock(mode) do
        Table.lock(unquote(name), mode)
      end

      def destroy do
        Table.destroy(unquote(name))
      end

      def clear do
        Table.clear(unquote(name))
      end

      def read(key, lock // :read) do
        Table.read(unquote(name), key, lock)
      end

      def read!(key) do
        Table.read!(unquote(name), key)
      end

      def keys do
        Table.keys(unquote(name))
      end

      def keys! do
        Table.keys!(unquote(name))
      end

      def first do
        Table.first(unquote(name))
      end

      def first! do
        Table.first!(unquote(name))
      end

      def key(self) do
        elem self, Enum.at!(unquote(indices), 0)
      end

      def next(self) do
        Table.next(unquote(name), self.key)
      end

      def next!(self) do
        Table.next!(unquote(name), self.key)
      end

      def prev(self) do
        Table.prev(unquote(name), self.key)
      end

      def prev!(self) do
        Table.prev!(unquote(name), self.key)
      end

      def last do
        Table.last(unquote(name))
      end

      def last! do
        Table.last!(unquote(name))
      end

      def delete(self) do
        :mnesia.delete_object(self)
      end

      def delete!(self) do
        :mnesia.dirty_delete_object(self)
      end

      def delete(key, self) do
        Table.delete(unquote(name), key)
      end

      def delete!(key, self) do
        Table.delete!(unquote(name), key)
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
