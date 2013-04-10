#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defrecord Amnesia.Counter, [:name, :table] do
  @type t :: Amnesia.Counter[name: atom, table: atom]

  @doc """
  Create a counter with the given name, optional table name and optional
  copying mode.

  If no table name is given a global table will be used, so name clashing is
  possible and the copying mode is linked to the previously created counters.
  """
  @spec create(atom, atom, Amnesia.Table.c) :: t
  def create(name, table // Amnesia.Counter, copying // []) do
    Amnesia.Table.create(table, [
      record_name: table,
      attributes:  [:name, :value]
    ])

    Amnesia.Counter[name: name, table: table]
  end

  @doc """
  Destroy the counter, keep in mind that destroying a counter on the same
  table, destroy every other counter.
  """
  @spec destroy(t) :: { :atomic, :ok } | { :aborted, any }
  def destroy(self) do
    Amnesia.Table.destroy(self.table)
  end

  @doc """
  Increase the counter by 1.
  """
  @spec increase(t) :: integer | no_return
  def increase(self) do
    increase(1, self)
  end

  @doc """
  Increase the counter by the given amount.
  """
  @spec increase(integer, t) :: integer | no_return
  def increase(much, self) do
    :mnesia.dirty_update_counter(self.table, self.name, much)
  end

  @doc """
  Get the current value of the counter.
  """
  @spec value(t) :: integer | no_return
  def value(self) do
    case :mnesia.read(self.table, self.name) do
      [{ _, _, value }] -> value
      _                 -> 0
    end
  end

  @doc """
  Get the current value of the counter.
  """
  @spec value!(t) :: integer | no_return
  def value!(self) do
    case :mnesia.dirty_read(self.table, self.name) do
      [{ _, _, value }] -> value
      _                 -> 0
    end
  end
end
