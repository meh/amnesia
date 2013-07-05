#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Sequence do
  @moduledoc """
  This sequence wraps a table with certain options and allows you to use Enum
  functions on the records in the table.

  This module uses `first`, `last`, `next`, `prev` and `read`, so be sure to
  understand what this entails when using it.
  """

  @opaque t :: record

  defrecordp :sequence, table: nil, type: nil, lock: :read, key: nil, dirty: false, reverse: false

  def new(name, type, rest) do
    lock    = Keyword.get(rest, :lock,    :read)
    dirty   = Keyword.get(rest, :dirty,   false)
    reverse = Keyword.get(rest, :reverse, false)

    sequence(table: name, type: type, lock: lock, dirty: dirty, reverse: reverse)
  end

  @doc """
  Check if the table wrapped by the sequence is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(sequence(type: type)) do
    type == :bag
  end

  @doc """
  Check if the table wrapped by the sequence is a set.
  """
  @spec set?(t) :: boolean
  def set?(sequence(type: type)) do
    type == :set
  end

  @doc """
  Check if the table wrapped by the sequence is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(sequence(type: type)) do
    type == :ordered_set
  end

  @doc """
  Check if the sequence uses dirty operations.
  """
  @spec dirty?(t) :: boolean
  def dirty?(sequence(dirty: dirty)) do
    dirty
  end

  @doc """
  Check if the sequence is a reverse sequence.
  """
  @spec reverse?(t) :: boolean
  def reverse?(sequence(reverse: reverse)) do
    reverse
  end

  def reverse(sequence(reverse: reverse) = self) do
    sequence(self, reverse: !reverse)
  end

  # no key, first time being called
  def first(sequence(table: table, lock: lock, dirty: false, reverse: false, key: nil)) do
    if key = table.first(true) do
      table.read(key, lock)
    end
  end

  def first(sequence(table: table, dirty: true, reverse: false, key: nil)) do
    if key = table.first!(true) do
      table.read!(key)
    end
  end

  def first(sequence(table: table, lock: lock, dirty: false, reverse: true, key: nil)) do
    if key = table.last(true) do
      table.read(key, lock)
    end
  end

  def first(sequence(table: table, dirty: true, reverse: true, key: nil)) do
    if key = table.last!(true) do
      table.read!(key)
    end
  end

  # key present, next has been called
  def first(sequence(table: table, lock: lock, dirty: false, key: key)) do
    table.read(key, lock)
  end

  def first(sequence(table: table, dirty: true, key: key)) do
    table.read!(key)
  end

  # no key, first time being called
  def next(sequence(table: table, dirty: false, reverse: false, key: nil) = it) do
    if key = table.first(true) do
      if key = table.next(key) do
        sequence(it, key: key)
      end
    end
  end

  def next(sequence(table: table, dirty: true, reverse: false, key: nil) = it) do
    if key = table.first!(true) do
      if key = table.next!(key) do
        sequence(it, key: key)
      end
    end
  end

  def next(sequence(table: table, dirty: false, reverse: true, key: nil) = it) do
    if key = table.last(true) do
      if key = table.prev(key) do
        sequence(it, key: key)
      end
    end
  end

  def next(sequence(table: table, dirty: true, reverse: true, key: nil) = it) do
    if key = table.last!(true) do
      if key = table.prev!(key) do
        sequence(it, key: key)
      end
    end
  end

  # key present, next has been called
  def next(sequence(table: table, dirty: false, reverse: false, key: key) = it) do
    if key = table.next(key) do
      sequence(it, key: key)
    end
  end

  def next(sequence(table: table, dirty: true, reverse: false, key: key) = it) do
    if key = table.next!(key) do
      sequence(it, key: key)
    end
  end

  def next(sequence(table: table, dirty: false, reverse: true, key: key) = it) do
    if key = table.prev(key) do
      sequence(it, key: key)
    end
  end

  def next(sequence(table: table, dirty: true, reverse: true, key: key) = it) do
    if key = table.prev!(key) do
      sequence(it, key: key)
    end
  end
end

defimpl Data.Sequence, for: Amnesia.Table.Sequence do
  def first(self) do
    self.first
  end

  def next(self) do
    self.next
  end
end

defimpl Data.Reducible, for: Amnesia.Table.Sequence do
  def reduce(self, acc, fun) do
    Data.Seq.reduce(self, acc, fun)
  end
end

defimpl Data.Counted, for: Amnesia.Table.Sequence do
  def count(self) do
    Amnesia.Table.info(self.table, :size)
  end
end

defimpl Data.Reversible, for: Amnesia.Table.Sequence do
  def reverse(self) do
    self.reverse
  end
end

defimpl Data.Contains, for: Amnesia.Table.Sequence do
  def contains?(self, key) do
    Amnesia.Table.member?(self.table, key)
  end
end

defimpl Enumerable, for: Amnesia.Table.Sequence do
  use Data.Enumerable
end
