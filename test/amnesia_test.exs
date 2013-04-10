Code.require_file "../test_helper.exs", __FILE__

defmodule AmnesiaTest do
  use ExUnit.Case
  use Amnesia

  defdatabase Database do
    deftable Message, [:user_id, :content], type: :bag do
      @type t :: __MODULE__[user_id: integer, content: String.t]

      def user(self) do
        User.read(self.user_id)
      end

      def user!(self) do
        User.read!(self.user_id)
      end
    end

    deftable User, [:id, :name, :email] do
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
    assert Database.User.set?
    assert Database.Message.bag?
  end

  test "saves item" do
    transaction! do
      user = Database.User[id: 23]
      user.add_message("yo dawg")
      user.write
    end

    assert(transaction! do
      assert Database.User.read(23) == Database.User[id: 23]
      assert Database.User.read(23).messages == [Database.Message[user_id: 23, content: "yo dawg"]]

      :ok
    end == { :atomic, :ok })
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
    Database.create

    :ok
  end

  teardown do
    Database.destroy

    :ok
  end
end
