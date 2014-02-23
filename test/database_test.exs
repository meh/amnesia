Code.require_file "test_helper.exs", __DIR__

use Amnesia

defdatabase Test.Database do
  deftable User

  deftable Message, [:user_id, :content], type: :bag do
    @type t :: Message[user_id: integer, content: String.t]

    def user(self) do
      User.read(self.user_id)
    end

    def user!(self) do
      User.read!(self.user_id)
    end
  end

  deftable User, [{ :id, autoincrement }, :name, :email], type: :ordered_set, index: [:email] do
    @type t :: User[id: integer, name: String.t, email: String.t]

    def add_message(content, self) do
      Message[user_id: self.id, content: content].write
    end

    def add_message!(content, self) do
      Message[user_id: self.id, content: content].write!
    end

    def messages(self) do
      Message.read(self.id)
    end

    def messages!(self) do
      Message.read!(self.id)
    end
  end
end

defmodule DatabaseTest do
  use ExUnit.Case
  use Test.Database
  alias Data.Seq

  test "type checking works" do
    assert User.ordered_set?
    assert Message.bag?
  end

  test "saves item" do
    Amnesia.transaction! do
      user = User[id: 23]
      user.add_message("yo dawg")
      user.write
    end

    Seq.first(User.read!(23).messages!).user!

    assert(Amnesia.transaction! do
      assert User.read(23) == User[id: 23]
      assert User.read(23).messages == [Message[user_id: 23, content: "yo dawg"]]
      assert Seq.first(User.read(23).messages).user == User[id: 23]
    end == true)
  end

  test "read returns nil when empty" do
    assert(Amnesia.transaction! do
      assert User.read(23) == nil
      assert Message.read(23) == nil
    end == true)
  end

  test "async dirty functionality works" do
    Amnesia.async do
      user = User[id: 23]
      user.add_message("yo dawg")
      user.write
    end

    assert(Amnesia.async do
      assert User.read(23) == User[id: 23]
      assert User.read(23).messages == [Message[user_id: 23, content: "yo dawg"]]
      assert Seq.first(User.read(23).messages).user == User[id: 23]
    end == true)
  end

  
  test "sync dirty functionality works" do
    Amnesia.sync do
      user = User[id: 23]
      user.add_message("yo dawg")
      user.write
    end

    assert(Amnesia.sync do
      assert User.read(23) == User[id: 23]
      assert User.read(23).messages == [Message[user_id: 23, content: "yo dawg"]]
      assert Seq.first(User.read(23).messages).user == User[id: 23]
    end == true)
  end

  test "first fetches a key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.first(true) == 1
    end == true)
  end

  test "first fetches the record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.first == User[id: 1, name: "John"]
    end == true)
  end

  test "next fetches the next key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.next(User.first(true)) == 2
    end == true)
  end

  test "next fetches the next record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.first.next == User[id: 2, name: "Lucas"]
    end == true)
  end

  test "prev fetches the prev key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.prev(User.last(true)) == 2
    end == true)
  end

  test "prev fetches the prev record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last.prev == User[id: 2, name: "Lucas"]
    end == true)
  end

  test "last fetches a key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last(true) == 3
    end == true)
  end

  test "last fetches the record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last == User[id: 3, name: "David"]
    end == true)
  end

  test "delete deletes the record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last == User[id: 3, name: "David"]
      assert User.last.delete == :ok
    end == true)

    assert(Amnesia.transaction! do
      assert User.last == User[id: 2, name: "Lucas"]
    end == true)
  end

  test "match matches records" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.match(name: "Lucas").values ==
        [User[id: 2, name: "Lucas"]]
    end == true)
  end

  test "select works" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.select([{ User[id: :'$1', name: :'$2', _: :_],
        [{ :'==', "John", :'$2' }], [:'$1'] }]).values == [1]
    end == true)
  end

  test "select works with limit" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      selection = User.select(1, [{ User[id: :'$1', _: :_], [], [:'$1'] }])
      assert selection.values == [1]

      selection = selection.next
      assert selection.values == [2]

      selection = selection.next
      assert selection.values == [3]

      assert selection.next == nil
    end == true)
  end

  test "where works" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.where(name == "John", select: id).values == [1]
    end == true)
  end

  test "where works with limit" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      selection = User.where(true, select: id, limit: 1)
      assert selection.values == [1]

      selection = selection.next
      assert selection.values == [2]

      selection = selection.next
      assert selection.values == [3]

      assert selection.next == nil
    end == true)
  end

  test "qualified where works" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.where(user.name == "John", select: user.id, qualified: true).values == [1]
    end == true)
  end

  test "specced where works" do
    Amnesia.transaction! do
      User[id: { 1, 1 }, name: "John"].write
      User[id: { 2, 1 }, name: "Lucas"].write
      User[id: { 3, 1 }, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.where(id.first == 1, in: [id: { first, second }], select: id.first).values == [1]
    end == true)
  end

  test "read_at works" do
    Amnesia.transaction! do
      User[id: 1, name: "John", email: "john@email.com"].write
      User[id: 2, name: "Lucas", email: "lucas@email.com"].write
      User[id: 3, name: "David", email: "david@email.com"].write
    end

    assert(Amnesia.transaction! do
      assert User.read_at("john@email.com", :email) == [User[id: 1, name: "John", email: "john@email.com"]]
    end == true)
  end

  test "enumerator works" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Enum.map(User.to_sequence, fn(user) ->
        user.id
      end) == [1, 2, 3]
    end == true)
  end

  test "reverse enumerator works" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Enum.map(User.to_sequence.reverse, fn(user) ->
        user.id
      end) == [3, 2, 1]
    end == true)
  end

  test "autoincrement works" do
    Amnesia.transaction! do
      User[name: "John"].write
      User[name: "Lucas"].write
      User[name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.read(1).name == "John"
      assert User.read(2).name == "Lucas"
      assert User.read(3).name == "David"
    end == true)
  end

  setup_all do
    Amnesia.Test.start
  end

  teardown_all do
    Amnesia.Test.stop
  end

  setup do
    Test.Database.create!

    :ok
  end

  teardown do
    Test.Database.destroy

    :ok
  end
end
