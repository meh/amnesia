#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defrecord Amnesia.Table.Iterator, table: nil, type: nil, lock: :read, key: nil, dirty: false, reverse: false do
  @moduledoc """
  This iterator wraps a table with certain options and allows you to use Enum
  functions on the records in the table.

  This module uses `first`, `last`, `next`, `prev` and `read`, so be sure to
  understand what this entails when using it.
  """

  @type t :: __MODULE__[table: atom, type: atom, key: any, dirty: boolean, reverse: boolean]

  @doc """
  Check if the table wrapped by the iterator is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(self) do
    self.type == :bag
  end

  @doc """
  Check if the table wrapped by the iterator is a set.
  """
  @spec set?(t) :: boolean
  def set?(self) do
    self.type == :set
  end

  @doc """
  Check if the table wrapped by the iterator is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(self) do
    self.type == :ordered_set
  end

  @doc """
  Check if the iterator uses dirty operations.
  """
  @spec dirty?(t) :: boolean
  def dirty?(self) do
    self.dirty
  end

  @doc """
  Check if the iterator is a reverse iterator.
  """
  @spec reverse?(t) :: boolean
  def reverse?(self) do
    self.reverse
  end

  @doc false
  def iterate(Amnesia.Table.Iterator[dirty: false, reverse: false] = it) do
    if it.key == nil do
      it = it.key(Amnesia.Table.first(it.table))
    end

    current = Amnesia.Table.read(it.table, it.key, it.lock)
    next    = it.key(Amnesia.Table.next(it.table, it.key))

    { if(it.bag?, do: current, else: hd(current)), if(next.key, do: next, else: nil) }
  end

  def iterate(Amnesia.Table.Iterator[dirty: true, reverse: false] = it) do
    if it.key == nil do
      it = it.key(Amnesia.Table.first!(it.table))
    end

    current = Amnesia.Table.read!(it.table, it.key)
    next    = it.key(Amnesia.Table.next!(it.table, it.key))

    { if(it.bag?, do: current, else: hd(current)), if(next.key, do: next, else: nil) }
  end

  def iterate(Amnesia.Table.Iterator[dirty: false, reverse: true] = it) do
    if it.key == nil do
      it = it.key(Amnesia.Table.last(it.table))
    end

    current = Amnesia.Table.read(it.table, it.key)
    prev    = it.key(Amnesia.Table.prev(it.table, it.key))

    { if(it.bag?, do: current, else: hd(current)), if(prev.key, do: prev, else: nil) }
  end

  def iterate(Amnesia.Table.Iterator[dirty: true, reverse: true] = it) do
    if it.key == nil do
      it = it.key(Amnesia.Table.last!(it.table))
    end

    current = Amnesia.Table.read!(it.table, it.key)
    prev    = it.key(Amnesia.Table.prev!(it.table, it.key))

    { if(it.bag?, do: current, else: hd(current)), if(prev.key, do: prev, else: nil) }
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
