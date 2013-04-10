Code.require_file "../test_helper.exs", __FILE__

defmodule AmnesiaTest do
  use ExUnit.Case
  use Amnesia

  defdatabase Database do
    deftable User

    deftable Message, [:user_id, :content], type: :bag do
      @type t :: __MODULE__[user_id: integer, content: String.t]

      def user(self) do
        User.read(self.user_id)
      end

      def user!(self) do
        User.read!(self.user_id)
      end
    end

    deftable User, [:id, :name, :email], type: :ordered_set, index: [:email] do
      @type t :: __MODULE__[id: integer, name: String.t, email: String.t]

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
    transaction! do
      user = Database.User[id: 23]
      user.add_message("yo dawg")
      user.write
    end

    Enum.first(Database.User.read!(23).messages!).user!

    assert(transaction! do
      assert Database.User.read(23) == Database.User[id: 23]
      assert Database.User.read(23).messages == [Database.Message[user_id: 23, content: "yo dawg"]]
      assert Enum.first(Database.User.read(23).messages).user == Database.User[id: 23]
    end == { :atomic, true })
  end

  test "first fetches a key" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.first(true) == 1
    end == { :atomic, true })
  end

  test "first fetches the record" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.first == Database.User[id: 1, name: "John"]
    end == { :atomic, true })
  end

  test "next fetches the next key" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.next(Database.User.first(true)) == 2
    end == { :atomic, true })
  end

  test "next fetches the next record" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.first.next == Database.User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "prev fetches the prev key" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.prev(Database.User.last(true)) == 2
    end == { :atomic, true })
  end

  test "prev fetches the prev record" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.last.prev == Database.User[id: 2, name: "Lucas"]
    end == { :atomic, true })
  end

  test "last fetches a key" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.last(true) == 3
    end == { :atomic, true })
  end

  test "last fetches the record" do
    transaction! do
      Database.User[id: 1, name: "John"].write
      Database.User[id: 2, name: "Lucas"].write
      Database.User[id: 3, name: "David"].write
    end

    assert(transaction! do
      assert Database.User.last == Database.User[id: 3, name: "David"]
    end == { :atomic, true })
  end

  setup_all do
    :error_logger.tty(false)

    Amnesia.Schema.create
    Amnesia.start

    :ok
  end

  teardown_all do
    Amnesia.stop
    Amnesia.Schema.destroy

    :error_logger.tty(true)

    :ok
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
