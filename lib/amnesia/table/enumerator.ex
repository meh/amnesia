#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Enumerator do
  @moduledoc """
  This enumerator wraps a table with certain options and allows you to use Enum
  functions on the records in the table.

  This module uses `first`, `last`, `next`, `prev` and `read`, so be sure to
  understand what this entails when using it.
  """

  @opaque t :: record

  defrecordp :enumerator, table: nil, type: nil, lock: :read, key: nil, dirty: false, reverse: false

  def new(name, type, rest) do
    lock    = Keyword.get(rest, :lock,    :read)
    dirty   = Keyword.get(rest, :dirty,   false)
    reverse = Keyword.get(rest, :reverse, false)

    enumerator(table: name, type: type, lock: lock, dirty: dirty, reverse: reverse)
  end

  @doc """
  Check if the table wrapped by the enumerator is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(enumerator(type: type)) do
    type == :bag
  end

  @doc """
  Check if the table wrapped by the enumerator is a set.
  """
  @spec set?(t) :: boolean
  def set?(enumerator(type: type)) do
    type == :set
  end

  @doc """
  Check if the table wrapped by the enumerator is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(enumerator(type: type)) do
    type == :ordered_set
  end

  @doc """
  Check if the enumerator uses dirty operations.
  """
  @spec dirty?(t) :: boolean
  def dirty?(enumerator(dirty: dirty)) do
    dirty
  end

  @doc """
  Check if the enumerator is a reverse enumerator.
  """
  @spec reverse?(t) :: boolean
  def reverse?(enumerator(reverse: reverse)) do
    reverse
  end

  def reverse(enumerator(reverse: reverse) = self) do
    enumerator(self, reverse: !reverse)
  end

  @doc false
  def iterate(enumerator(table: table, lock: lock, dirty: false, reverse: false) = it) do
    if enumerator(it, :key) == nil do
      it = enumerator(it, key: Amnesia.Table.first(table))
    end

    current = Amnesia.Table.read(table, enumerator(it, :key), lock)
    next    = enumerator(it, key: Amnesia.Table.next(table, enumerator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(enumerator(next, :key), do: next) }
  end

  def iterate(enumerator(table: table, dirty: true, reverse: false) = it) do
    if enumerator(it, :key) == nil do
      it = enumerator(it, key: Amnesia.Table.first!(table))
    end

    current = Amnesia.Table.read!(table, enumerator(it, :key))
    next    = enumerator(it, key: Amnesia.Table.next!(table, enumerator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(enumerator(next, :key), do: next) }
  end

  def iterate(enumerator(table: table, lock: lock, dirty: false, reverse: true) = it) do
    if enumerator(it, :key) == nil do
      it = enumerator(it, key: Amnesia.Table.last(table))
    end

    current = Amnesia.Table.read(table, enumerator(it, :key), lock)
    prev    = enumerator(it, key: Amnesia.Table.prev(table, enumerator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(enumerator(prev, :key), do: prev) }
  end

  def iterate(enumerator(table: table, dirty: true, reverse: true) = it) do
    if enumerator(it, :key) == nil do
      it = enumerator(it, key: Amnesia.Table.last!(table))
    end

    current = Amnesia.Table.read!(table, enumerator(it, :key))
    prev    = enumerator(it, key: Amnesia.Table.prev!(table, enumerator(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(enumerator(prev, :key), do: prev) }
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
    Amnesia.Table.member?(enum.table, key)
  end

  def count(enum) do
    Amnesia.Table.info(enum.table, :size)
  end
end
