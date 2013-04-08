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
end
