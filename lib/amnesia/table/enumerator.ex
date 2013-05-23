#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Enumerator do
  @moduledoc """
  This iterator wraps a table with certain options and allows you to use Enum
  functions on the records in the table.

  This module uses `first`, `last`, `next`, `prev` and `read`, so be sure to
  understand what this entails when using it.
  """

  @opaque t :: record

  defrecordp :iterator, table: nil, type: nil, lock: :read, key: nil, dirty: false, reverse: false

  def new(name, type, rest) do
    if :mnesia.first(name) == :'$end_of_table' do
      []
    else
      lock    = Keyword.get(rest, :lock,    :read)
      dirty   = Keyword.get(rest, :dirty,   false)
      reverse = Keyword.get(rest, :reverse, false)

      iterator(table: name, type: type, lock: lock, dirty: dirty, reverse: reverse)
    end
  end

  @doc """
  Check if the table wrapped by the iterator is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(iterator(type: type)) do
    type == :bag
  end

  @doc """
  Check if the table wrapped by the iterator is a set.
  """
  @spec set?(t) :: boolean
  def set?(iterator(type: type)) do
    type == :set
  end

  @doc """
  Check if the table wrapped by the iterator is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(iterator(type: type)) do
    type == :ordered_set
  end

  @doc """
  Check if the iterator uses dirty operations.
  """
  @spec dirty?(t) :: boolean
  def dirty?(iterator(dirty: dirty)) do
    dirty
  end

  @doc """
  Check if the iterator is a reverse iterator.
  """
  @spec reverse?(t) :: boolean
  def reverse?(iterator(reverse: reverse)) do
    reverse
  end

  def reverse(iterator(reverse: reverse) = self) do
    iterator(self, reverse: !reverse)
  end

  @doc false
  def iterate(iterator(table: table, lock: lock, dirty: false, reverse: false) = it) do
    if iterator(it, :key) == nil do
      it = iterator(it, key: Amnesia.Table.first(table))
    end

    current = Amnesia.Table.read(table, iterator(it, :key), lock)
    next    = iterator(it, key: Amnesia.Table.next(table, iterator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(iterator(next, :key), do: next) }
  end

  def iterate(iterator(table: table, dirty: true, reverse: false) = it) do
    if iterator(it, :key) == nil do
      it = iterator(it, key: Amnesia.Table.first!(table))
    end

    current = Amnesia.Table.read!(table, iterator(it, :key))
    next    = iterator(it, key: Amnesia.Table.next!(table, iterator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(iterator(next, :key), do: next) }
  end

  def iterate(iterator(table: table, lock: lock, dirty: false, reverse: true) = it) do
    if iterator(it, :key) == nil do
      it = iterator(it, key: Amnesia.Table.last(table))
    end

    current = Amnesia.Table.read(table, iterator(it, :key), lock)
    prev    = iterator(it, key: Amnesia.Table.prev(table, iterator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(iterator(prev, :key), do: prev) }
  end

  def iterate(iterator(table: table, dirty: true, reverse: true) = it) do
    if iterator(it, :key) == nil do
      it = iterator(it, key: Amnesia.Table.last!(table))
    end

    current = Amnesia.Table.read!(table, iterator(it, :key))
    prev    = iterator(it, key: Amnesia.Table.prev!(table, iterator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(iterator(prev, :key), do: prev) }
  end

  def iterate(nil) do
    :stop
  end
end

defimpl Enumerable, for: Amnesia.Table.Enumerator do
  def reduce(:stop, acc, _) do
    acc
  end

  def reduce({ h, next }, acc, fun) do
    reduce(Amnesia.Table.Enumerator.iterate(next), fun.(h, acc), fun)
  end

  def reduce(enum, acc, fun) do
    reduce(Amnesia.Table.Enumerator.iterate(enum), acc, fun)
  end

  def member?(enum, key) do
    Amnesia.Table.read!(enum.table, key) != nil
  end

  def count(enum) do
    Amnesia.Table.info(enum.table, :size)
  end
end
