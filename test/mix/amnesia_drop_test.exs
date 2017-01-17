Code.require_file "mix_helper.exs", __DIR__

use Amnesia

defdatabase Drop.Database do
  deftable User

  deftable Message, [:user_id, :content], type: :bag do
    def user(self) do
      User.read(self.user_id)
    end

    def user!(self) do
      User.read!(self.user_id)
    end
  end

  deftable User, [{ :id, autoincrement }, :name, :email], type: :ordered_set, index: [:email] do
    def add_message(self, content) do
      %Message{user_id: self.id, content: content} |> Message.write
    end

    def add_message!(self, content) do
      %Message{user_id: self.id, content: content} |> Message.write!
    end

    def messages(self) do
      Message.read(self.id)
    end

    def messages!(self) do
      Message.read!(self.id)
    end

    def odd do
      where rem(id, 2) == 1,
        select: name
    end
  end
end

defmodule Drop.NotADatabase do
end

defmodule Mix.Tasks.Amnesia.Drop.Test do
  use ExUnit.Case
  use Drop.Database

  alias Drop.Database, as: DB
  alias Mix.Tasks.Amnesia.Drop

  setup do
    Amnesia.Schema.create
    Amnesia.start

    DB.create(memory: [node()])
    :ok = DB.wait 15000
    Amnesia.stop

    on_exit fn -> Amnesia.stop end
  end

  test "drops tables and schema" do
    Drop.run(["-d", "Drop.Database", "--schema"])
    Amnesia.start
    assert Amnesia.info(:tables) == [:schema] # this table exists
  end

  test "detects module is not a database" do
    assert_raise Mix.Error, fn ->
      Drop.run(["-d", "Drop.NotADatabase"])
    end
  end

end
