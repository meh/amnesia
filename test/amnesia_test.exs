Code.require_file "../test_helper.exs", __FILE__

defmodule AmnesiaTest do
  use ExUnit.Case
  use Amnesia

  defdatabase Database do
    deftable Message, [:user, :message], type: :bag do
      @type t :: __MODULE__[user: integer, message: String.t]

      def bar do
        42
      end
    end

    deftable User, [:id, :name, :email] do
      @type t :: __MODULE__[id: integer, name: String.t, email: String.t]
    end
  end

  test "type checking works" do
    assert Database.Message.bag?
    assert Database.User.set?
  end

  test "saves item" do
    transaction! do
      Database.Message[user: 23, message: "yo dawg"].write
    end

    assert(transaction! do
      Database.Message.read(23)
    end == { :atomic, [Database.Message[user: 23, message: "yo dawg"]] })
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
