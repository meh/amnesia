#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defrecord Amnesia.Counter, [:name, :table] do
  def create(name, table // Amnesia.Counter, copying // []) do
    Amnesia.Table.create(table, [
      record_name: table,
      attributes:  [:name, :value]
    ])

    Amnesia.Counter[name: name, table: table]
  end

  def destroy(self) do
    Amnesia.Table.destroy(self.table)
  end

  def increase(self) do
    increase(1, self)
  end

  def increase(much, self) do
    :mnesia.dirty_update_counter(self.table, self.name, much)
  end

  def value(self) do
    case :mnesia.read(self.table, self.name) do
      [{ _, _, value }] -> value
      _                 -> 0
    end
  end

  def value!(self) do
    case :mnesia.dirty_read(self.table, self.name) do
      [{ _, _, value }] -> value
      _                 -> 0
    end
  end
end
