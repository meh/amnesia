Code.require_file "test_helper.exs", __DIR__

use Amnesia

defdatabase Test.Database do
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

defmodule DatabaseTest do
  use ExUnit.Case
  use Test.Database

  alias Amnesia.Selection
  alias Amnesia.Table.Stream

  test "match can use variables" do
    user = Amnesia.transaction! do
      %User{id: 23} |> User.write
      query = [id: 23]
      User.match(query)
    end

    assert [%Test.Database.User{id: 23} | _] = user |> Amnesia.Selection.values
  end

  test "type checking works" do
    assert User.ordered_set?
    assert Message.bag?
  end

  test "saves item" do
    Amnesia.transaction! do
      user = %User{id: 23}
      user |> User.add_message("yo dawg")
      user |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.read(23) == %User{id: 23}
      assert User.read(23) |> User.messages == [%Message{user_id: 23, content: "yo dawg"}]
      assert Enum.at(User.read(23) |> User.messages, 0) |> Message.user == %User{id: 23}
    end == true)
  end

  test "read returns nil when empty" do
    assert(Amnesia.transaction! do
      assert User.read(23) == nil
      assert Message.read(23) == nil
    end == true)
  end

  test "first fetches a key" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.first(true) == 1
    end == true)
  end

  test "first fetches the record" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.first == %User{id: 1, name: "John"}
    end == true)
  end

  test "next fetches the next key" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.next(User.first(true)) == 2
    end == true)
  end

  test "next fetches the next record" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.first |> User.next == %User{id: 2, name: "Lucas"}
    end == true)
  end

  test "prev fetches the prev key" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.prev(User.last(true)) == 2
    end == true)
  end

  test "prev fetches the prev record" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.last |> User.prev == %User{id: 2, name: "Lucas"}
    end == true)
  end

  test "last fetches a key" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.last(true) == 3
    end == true)
  end

  test "last fetches the record" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.last == %User{id: 3, name: "David"}
    end == true)
  end

  test "delete deletes the record" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.last == %User{id: 3, name: "David"}
      assert User.last |> User.delete == :ok
    end == true)

    assert(Amnesia.transaction! do
      assert User.last == %User{id: 2, name: "Lucas"}
    end == true)
  end

  test "match matches records" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert Selection.values(User.match(name: "Lucas")) ==
        [%User{id: 2, name: "Lucas"}]
    end == true)
  end

  test "select works" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert Selection.values(User.select([{ { User, :'$1', :'$2', :_ },
        [{ :'==', "John", :'$2' }], [:'$1'] }])) == [1]
    end == true)
  end

  test "select works with limit" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      selection = User.select(1, [{ { User, :'$1', :_, :_ }, [], [:'$1'] }])
      assert Selection.values(selection) == [1]

      selection = Selection.next(selection)
      assert Selection.values(selection) == [2]

      selection = Selection.next(selection)
      assert Selection.values(selection) == [3]

      assert Selection.next(selection) == nil
    end == true)
  end

  test "where works" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert Selection.values(User.where(name == "John", select: id)) == [1]
      assert User.where(name == "Richard") == nil
    end == true)
  end

  test "where works with limit" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      selection = User.where(true, select: id, limit: 1)
      assert Selection.values(selection) == [1]

      selection = Selection.next(selection)
      assert Selection.values(selection) == [2]

      selection = Selection.next(selection)
      assert Selection.values(selection) == [3]

      assert Selection.next(selection) == nil
    end == true)
  end

  test "qualified where works" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.where(user.name == "John", select: user.id, qualified: true).values == [1]
    end == true)
  end

  test "specced where works" do
    Amnesia.transaction! do
      %User{id: { 1, 1 }, name: "John"} |> User.write
      %User{id: { 2, 1 }, name: "Lucas"} |> User.write
      %User{id: { 3, 1 }, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.where(id.first == 1, in: [id: { first, second }], select: id.first).values == [1]
    end == true)
  end

  test "where works inside the module itself" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert Selection.values(User.odd) == ["John", "David"]
    end == true)
  end

  test "read_at works" do
    Amnesia.transaction! do
      %User{id: 1, name: "John", email: "john@email.com"} |> User.write
      %User{id: 2, name: "Lucas", email: "lucas@email.com"} |> User.write
      %User{id: 3, name: "David", email: "david@email.com"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.read_at("john@email.com", :email) == [%User{id: 1, name: "John", email: "john@email.com"}]
    end == true)
  end

  test "enumerator works" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert Enum.map(User.stream, fn(user) ->
        user.id
      end) == [1, 2, 3]

      refute Enum.member?(User.stream, 4)
      assert Enum.member?(User.stream, %User{id: 1, name: "John"})
    end == true)
  end

  test "reverse enumerator works" do
    Amnesia.transaction! do
      %User{id: 1, name: "John"} |> User.write
      %User{id: 2, name: "Lucas"} |> User.write
      %User{id: 3, name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert Enum.map(User.stream |> Stream.reverse, fn(user) ->
        user.id
      end) == [3, 2, 1]

      refute Enum.member?(User.stream, 4)
      assert Enum.member?(User.stream, %User{id: 1, name: "John"})
    end == true)
  end

  test "autoincrement works" do
    Amnesia.transaction! do
      %User{name: "John"} |> User.write
      %User{name: "Lucas"} |> User.write
      %User{name: "David"} |> User.write
    end

    assert(Amnesia.transaction! do
      assert User.read(1).name == "John"
      assert User.read(2).name == "Lucas"
      assert User.read(3).name == "David"
    end == true)
  end

  setup_all do
    Amnesia.Test.start

    on_exit fn ->
      Amnesia.Test.stop
    end
  end

  setup do
    Test.Database.create!

    on_exit fn ->
      Test.Database.destroy
    end
  end
end
