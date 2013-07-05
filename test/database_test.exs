Code.require_file "../test_helper.exs", __FILE__

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

  deftable User, [:id, :name, :email], type: :ordered_set, index: [:email] do
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

    Enum.first(User.read!(23).messages!).user!

    assert(Amnesia.transaction! do
      assert User.read(23) == User[id: 23]
      assert User.read(23).messages == [Message[user_id: 23, content: "yo dawg"]]
      assert Enum.first(User.read(23).messages).user == User[id: 23]
    end == { :atomic, true })
  end

  test "read returns nil when empty" do
    assert(Amnesia.transaction! do
      assert User.read(23) == nil
      assert Message.read(23) == nil
    end == { :atomic, true })
  end

  test "first fetches a key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.first(true) == 1
    end == { :atomic, true })
  end

  test "first fetches the record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.first == User[id: 1, name: "John"]
    end == { :atomic, true })
  end

  test "next fetches the next key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.next(User.first(true)) == 2
    end == { :atomic, true })
  end

  test "next fetches the next record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.first.next == User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "prev fetches the prev key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.prev(User.last(true)) == 2
    end == { :atomic, true })
  end

  test "prev fetches the prev record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last.prev == User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "last fetches a key" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last(true) == 3
    end == { :atomic, true })
  end

  test "last fetches the record" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.last == User[id: 3, name: "David"]
    end == { :atomic, true })
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
    end == { :atomic, true })

    assert(Amnesia.transaction! do
      assert User.last == User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "match matches records" do
    Amnesia.transaction! do
      User[id: 1, name: "John"].write
      User[id: 2, name: "Lucas"].write
      User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert User.match(User[name: "Lucas", _: :_]).values ==
        [User[id: 2, name: "Lucas"]]
    end == { :atomic, true })
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
    end == { :atomic, true })
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
    end == { :atomic, true })
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
    end == { :atomic, true })
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
    end == { :atomic, true })
  end

  setup_all do
    Amnesia.Test.start
  end

  teardown_all do
    Amnesia.Test.stop
  end

  setup do
    Enum.all?(Test.Database.create, fn(result) ->
      result == { :atomic, :ok }
    end) && :ok
  end

  teardown do
    Test.Database.destroy

    :ok
  end
end
