#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Metadata do
  @type t :: term

  defrecordp :meta, __MODULE__, database: nil

  @doc """
  Get the metadata for the given database.
  """
  @spec for(atom) :: t
  def for(database) do
    meta(database: database)
  end

  @doc """
  Create the metadata table.
  """
  @spec create(Keyword.t, t) :: :ok | { :error, term }
  def create(options, meta(database: database)) do
    Amnesia.Table.create(database, Keyword.merge(options,
      [type: :set, record: database, attributes: [:key, :value]]))
  end

  @doc """
  Create the metadata table, raising in case of error.
  """
  @spec create!(Keyword.t, t) :: :ok | no_return
  def create!(options, meta(database: database)) do
    Amnesia.Table.create!(database, Keyword.merge(options,
      [type: :set, record: database, attributes: [:key, :value]]))
  end

  @doc """
  Destroy the metadata table.
  """
  @spec destroy(t) :: :ok | { :error, term }
  def destroy(meta(database: database)) do
    Amnesia.Table.destroy(database)
  end

  @doc """
  Destroy the metadata table, raising in case of error.
  """
  @spec destroy!(t) :: :ok | no_return
  def destroy!(meta(database: database)) do
    Amnesia.Table.destroy!(database)
  end

  @doc """
  Get a value from the metadata table.
  """
  @spec get(term, t) :: term | nil | no_return
  def get(key, meta(database: database)) do
    case Amnesia.Table.read(database, key) do
      nil     -> nil
      [value] -> value
    end
  end

  @doc """
  Get a value from the metadata table using a dirty read.
  """
  @spec get!(term, t) :: term | nil | no_return
  def get!(key, meta(database: database)) do
    case Amnesia.Table.read!(database, key) do
      nil     -> nil
      [value] -> value
    end
  end

  @doc """
  Set a value in the metadata table.
  """
  @spec set(term, term, t) :: :ok | no_return
  def set(key, value, meta(database: database)) do
    Amnesia.Table.write(database, { database, key, value })
  end

  @doc """
  Set a value in the metadata table using a dirty write.
  """
  @spec set!(term, term, t) :: :ok | no_return
  def set!(key, value, meta(database: database)) do
    Amnesia.Table.write!(database, { database, key, value })
  end

  @doc """
  Get the counter value for the given table and field.
  """
  @spec counter(module, atom, t) :: non_neg_integer
  def counter(table, field, self) do
    get({ table, field }, self) || 0
  end

  @doc """
  Get the counter value for the given table and field, with a dirty read.
  """
  @spec counter!(module, atom, t) :: non_neg_integer
  def counter!(table, field, self) do
    get!({ table, field }, self) || 0
  end

  @doc """
  Update the counter for the given table and field by the given value.
  """
  @spec counter(module, atom, integer, t) :: non_neg_integer
  def counter(table, field, value, meta(database: database)) do
    :mnesia.dirty_update_counter(database, { table, field }, value)
  end

  defdelegate counter(table, field, value, self), to: __MODULE__, as: :counter!
end
