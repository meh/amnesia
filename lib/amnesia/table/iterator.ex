#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Iterator do
  @moduledoc """
  This iterator wraps a table with certain options and allows you to use Enum
  functions on the records in the table.

  This module uses `first`, `last`, `next`, `prev` and `read`, so be sure to
  understand what this entails when using it.
  """

  @opaque t :: record

  defrecordp :self, table: nil, type: nil, lock: :read, key: nil, dirty: false, reverse: false

  def new(name, type, rest) do
    if :mnesia.first(name) == :'$end_of_table' do
      []
    else
      lock    = Keyword.get(rest, :lock,    :read)
      dirty   = Keyword.get(rest, :dirty,   false)
      reverse = Keyword.get(rest, :reverse, false)

      self(table: name, type: type, lock: lock, dirty: dirty, reverse: reverse)
    end
  end

  @doc """
  Check if the table wrapped by the iterator is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(self(type: type)) do
    type == :bag
  end

  @doc """
  Check if the table wrapped by the iterator is a set.
  """
  @spec set?(t) :: boolean
  def set?(self(type: type)) do
    type == :set
  end

  @doc """
  Check if the table wrapped by the iterator is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(self(type: type)) do
    type == :ordered_set
  end

  @doc """
  Check if the iterator uses dirty operations.
  """
  @spec dirty?(t) :: boolean
  def dirty?(self(dirty: dirty)) do
    dirty
  end

  @doc """
  Check if the iterator is a reverse iterator.
  """
  @spec reverse?(t) :: boolean
  def reverse?(self(reverse: reverse)) do
    reverse
  end

  @doc false
  def iterate(self(table: table, lock: lock, dirty: false, reverse: false) = it) do
    if self(it, :key) == nil do
      it = self(it, key: Amnesia.Table.first(table))
    end

    current = Amnesia.Table.read(table, self(it, :key), lock)
    next    = self(it, key: Amnesia.Table.next(table, self(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(self(next, :key), do: next) }
  end

  def iterate(self(table: table, dirty: true, reverse: false) = it) do
    if self(it, :key) == nil do
      it = self(it, key: Amnesia.Table.first!(table))
    end

    current = Amnesia.Table.read!(table, self(it, :key))
    next    = self(it, key: Amnesia.Table.next!(table, self(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(self(next, :key), do: next) }
  end

  def iterate(self(table: table, lock: lock, dirty: false, reverse: true) = it) do
    if self(it, :key) == nil do
      it = self(it, key: Amnesia.Table.last(table))
    end

    current = Amnesia.Table.read(table, self(it, :key), lock)
    prev    = self(it, key: Amnesia.Table.prev(table, self(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(self(prev, :key), do: prev) }
  end

  def iterate(self(table: table, dirty: true, reverse: true) = it) do
    if self(it, :key) == nil do
      it = self(it, key: Amnesia.Table.last!(table))
    end

    current = Amnesia.Table.read!(table, self(it, :key))
    prev    = self(it, key: Amnesia.Table.prev!(table, self(it, :key)))

    { if(it.bag?, do: current, else: hd(current)), if(self(prev, :key), do: prev) }
  end

  def iterate(nil) do
    :stop
  end
end

defimpl Enum.Iterator, for: Amnesia.Table.Iterator do
  def iterator(it) do
    { Amnesia.Table.Iterator.iterate(&1), Amnesia.Table.Iterator.iterate(it) }
  end

  def count(it) do
    Amnesia.Table.info(it.table, :size)
  end
end
