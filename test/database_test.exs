Code.require_file "../test_helper.exs", __FILE__

defmodule DatabaseTest do
  use ExUnit.Case
  use Amnesia

  defdatabase Database do
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

  test "type checking works" do
    assert Database.User.ordered_set?
    assert Database.Message.bag?
  end

  test "saves item" do
    Amnesia.transaction! do
      user = Database.User[id: 23]
      user.add_message("yo dawg")
      user.write
    end

    Enum.first(Database.User.read!(23).messages!).user!

    assert(Amnesia.transaction! do
      assert Database.User.read(23) == Database.User[id: 23]
      assert Database.User.read(23).messages == [Database.Message[user_id: 23, content: "yo dawg"]]
      assert Enum.first(Database.User.read(23).messages).user == Database.User[id: 23]
    end == { :atomic, true })
  end

  test "first fetches a key" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.first(true) == 1
    end == { :atomic, true })
  end

  test "first fetches the record" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.first == Database.User[id: 1, name: "John"]
    end == { :atomic, true })
  end

  test "next fetches the next key" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.next(Database.User.first(true)) == 2
    end == { :atomic, true })
  end

  test "next fetches the next record" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.first.next == Database.User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "prev fetches the prev key" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.prev(Database.User.last(true)) == 2
    end == { :atomic, true })
  end

  test "prev fetches the prev record" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.last.prev == Database.User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "last fetches a key" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.last(true) == 3
    end == { :atomic, true })
  end

  test "last fetches the record" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.last == Database.User[id: 3, name: "David"]
    end == { :atomic, true })
  end

  test "delete deletes the record" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.last == Database.User[id: 3, name: "David"]
      assert Database.User.last.delete == :ok
    end == { :atomic, true })

    assert(Amnesia.transaction! do
      assert Database.User.last == Database.User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "match matches records" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Database.User.match(Database.User[name: "Lucas", _: :_]) ==
        [Database.User[id: 2, name: "Lucas"]]
    end == { :atomic, true })
  end

  test "iterator works" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Enum.map(Database.User.iterator, fn(user) ->
        user.id
      end) == [1, 2, 3]
    end == { :atomic, true })
  end

  test "reverse iterator works" do
    Amnesia.transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(Amnesia.transaction! do
      assert Enum.map(Database.User.reverse_iterator, fn(user) ->
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
    Enum.all?(Database.create, fn(result) ->
      result == { :atomic, :ok }
    end) && :ok
  end

  teardown do
    Database.destroy

    :ok
  end
end
