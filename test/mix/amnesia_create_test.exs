Code.require_file "mix_helper.exs", __DIR__

use Amnesia

defdatabase Create.Database do
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

defmodule Create.NotADatabase do

end

# ordered_set cannot be used with disk! copying
defdatabase DiscOnly.Database do

  deftable Message, [:user_id, :content], type: :bag do
  end
end

defmodule Mix.Tasks.Amnesia.Create.Test do
  use ExUnit.Case
  use Create.Database
  alias Create.Database, as: DB
  alias Mix.Tasks.Amnesia.Create

  setup do
    Amnesia.stop
    Amnesia.Schema.destroy
  end

  test "creates schema and tables with --database" do
    Create.run(["--database", "Create.Database"])

    Amnesia.start
    tables = Amnesia.info(:tables)
    assert :schema in tables
    assert User in tables
    assert Message in tables
    assert DB in tables
  end

  test "creates schema and tables with -d" do
    Create.run(["-d", "Create.Database"])

    Amnesia.start
    tables = Amnesia.info(:tables)
    assert :schema in tables
    assert User in tables
    assert Message in tables
    assert DB in tables
  end

  test "detects module is not a database" do
    assert_raise Mix.Error, fn ->
      Create.run(["--database", "Create.NotADatabase"])
    end
  end

  test "creates database with disk option" do
    Create.run(["--database", "Create.Database", "--disk"])

    Amnesia.start
    tables = Amnesia.info(:tables)
    assert :schema in tables
    assert User in tables
    assert Message in tables
    assert DB in tables
    assert Amnesia.Table.info(User, :disc_copies) == [node()]
    assert Amnesia.Table.info(Message, :disc_copies) == [node()]
    assert Amnesia.Table.info(DB, :disc_copies) == [node()]
  end

  test "creates database with disk! option" do
    Create.run(["--database", "DiscOnly.Database", "--disk!"])

    Amnesia.start
    tables = Amnesia.info(:tables)
    assert :schema in tables
    assert DiscOnly.Database.Message in tables
    assert DiscOnly.Database in tables
    assert Amnesia.Table.info(DiscOnly.Database.Message, :disc_only_copies) == [node()]
  end

end
