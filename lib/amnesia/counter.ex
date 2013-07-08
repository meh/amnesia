#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Counter do
  @moduledoc """
  This module implements a simple interface to dirty counters.
  """

  @opaque t :: record

  defrecordp :counter, __MODULE__, name: nil, table: nil

  @doc """
  Create a table for the counter.
  """
  @spec create :: Amnesia.Table.o
  @spec create(atom) :: Amnesia.Table.o
  @spec create(atom, Amnesia.Table.c) :: Amnesia.Table.o
  def create(table // Amnesia.Counter, copying // []) do
    definition = Keyword.new

    if copying[:memory] do
      definition = Keyword.put(definition, :n_ram_copies, copying[:memory])
    end

    if copying[:disk] do
      definition = Keyword.put(definition, :n_disc_copies, copying[:disk])
    end

    if copying[:disk!] do
      definition = Keyword.put(definition, :n_disc_only_copies, copying[:disk!])
    end

    Amnesia.Table.create(table, Keyword.merge(definition, [
      record_name: table,
      attributes:  [:name, :value]
    ]))
  end

  @doc """
  Destroy the counter, keep in mind that destroying a counter on the same
  table, destroy every other counter.
  """
  @spec destroy(t | atom) :: Amnesia.Table.o
  def destroy(counter(table: table)) do
    Amnesia.Table.destroy(table)
  end

  def destroy(table) do
    Amnesia.Table.destroy(table)
  end

  def destroy do
    destroy(Amnesia.Counter)
  end

  @doc """
  Get a counter with the given name, optional table name and optional copying
  mode.

  If no table name is given a global table will be used, so name clashing is
  possible and the copying mode is linked to the previously created counters.
  """
  @spec get(atom) :: t
  @spec get(atom, atom) :: t
  @spec get(atom, atom, Amnesia.Table.c) :: t
  def get(name, table // Amnesia.Counter, copying // []) do
    create(table, copying)

    counter(name: name, table: table)
  end

  @spec name(t) :: atom
  def name(counter(name: name)) do
    name
  end

  @doc """
  Clear the counter inside a transaction.
  """
  @spec clear(t) :: :ok | no_return
  def clear(counter(name: name, table: table)) do
    Amnesia.Table.delete(table, name)
  end

  @doc """
  Clear the counter without a transaction.
  """
  @spec clear!(t) :: :ok | no_return
  def clear!(counter(name: name, table: table)) do
    Amnesia.Table.delete!(table, name)
  end

  @doc """
  Increase the counter by 1.
  """
  @spec increase(t) :: integer | no_return
  def increase(counter() = self) do
    increase(1, self)
  end

  @doc """
  Increase the counter by the given amount.
  """
  @spec increase(integer, t) :: integer | no_return
  def increase(much, counter(name: name, table: table)) do
    :mnesia.dirty_update_counter(table, name, much)
  end

  defdelegate increase!(self), to: __MODULE__, as: :increase
  defdelegate increase!(much, self), to: __MODULE__, as: :increase

  @doc """
  Get the current value of the counter.
  """
  @spec value(t) :: integer | no_return
  def value(counter(name: name, table: table)) do
    case :mnesia.read(table, name) do
      [{ _, _, value }] -> value
      _                 -> 0
    end
  end

  @doc """
  Get the current value of the counter.
  """
  @spec value!(t) :: integer | no_return
  def value!(counter(name: name, table: table)) do
    case :mnesia.dirty_read(table, name) do
      [{ _, _, value }] -> value
      _                 -> 0
    end
  end
end
