#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Metadata do
  alias __MODULE__, as: M

  defstruct [:database]
  @opaque t :: %__MODULE__{}

  @doc """
  Get the metadata for the given database.
  """
  @spec for(atom) :: t
  def for(database) do
    %M{database: database}
  end

  @doc """
  Create the metadata table.
  """
  @spec create(t, Keyword.t) :: :ok | { :error, term }
  def create(%M{database: database}, options) do
    Amnesia.Table.create(database, Keyword.merge(options,
      [type: :set, record: database, attributes: [:key, :value]]))
  end

  @doc """
  Create the metadata table, raising in case of error.
  """
  @spec create!(t, Keyword.t) :: :ok | no_return
  def create!(%M{database: database}, options) do
    Amnesia.Table.create!(database, Keyword.merge(options,
      [type: :set, record: database, attributes: [:key, :value]]))
  end

  @doc """
  Destroy the metadata table.
  """
  @spec destroy(t) :: :ok | { :error, term }
  def destroy(%M{database: database}) do
    Amnesia.Table.destroy(database)
  end

  @doc """
  Destroy the metadata table, raising in case of error.
  """
  @spec destroy!(t) :: :ok | no_return
  def destroy!(%M{database: database}) do
    Amnesia.Table.destroy!(database)
  end

  @doc """
  Get a value from the metadata table.
  """
  @spec get(t, term) :: term | nil | no_return
  def get(%M{database: database}, key) do
    case Amnesia.Table.read(database, key) do
      nil     -> nil
      [value] -> value
    end
  end

  @doc """
  Get a value from the metadata table using a dirty read.
  """
  @spec get!(t, term) :: term | nil | no_return
  def get!(%M{database: database}, key) do
    case Amnesia.Table.read!(database, key) do
      nil     -> nil
      [value] -> value
    end
  end

  @doc """
  Set a value in the metadata table.
  """
  @spec set(t, term, term) :: :ok | no_return
  def set(%M{database: database}, key, value) do
    Amnesia.Table.write(database, { database, key, value })
  end

  @doc """
  Set a value in the metadata table using a dirty write.
  """
  @spec set!(t, term, term) :: :ok | no_return
  def set!(%M{database: database}, key, value) do
    Amnesia.Table.write!(database, { database, key, value })
  end

  @doc """
  Get the counter value for the given table and field.
  """
  @spec counter(t, module, atom) :: non_neg_integer
  def counter(self, table, field) do
    get(self, { table, field }) || 0
  end

  @doc """
  Get the counter value for the given table and field, with a dirty read.
  """
  @spec counter!(t, module, atom) :: non_neg_integer
  def counter!(self, table, field) do
    get!(self, { table, field }) || 0
  end

  @doc """
  Update the counter for the given table and field by the given value.
  """
  @spec counter(t, module, atom, integer) :: non_neg_integer
  def counter(%M{database: database}, table, field, value) do
    :mnesia.dirty_update_counter(database, { table, field }, value)
  end

  defdelegate counter!(self, table, field, value), to: __MODULE__, as: :counter
end
