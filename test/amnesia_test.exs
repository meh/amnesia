Code.require_file "../test_helper.exs", __FILE__

defmodule AmnesiaTest do
  use ExUnit.Case
  use Amnesia

  defdatabase Database do
    deftable Foo, [:id, :message] do
      def bar do
        42
      end
    end
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

  test "saves item" do
    transaction! do
      Database.Foo[id: 23, message: "yo dawg"].write
    end

    assert(transaction! do
      Database.Foo.read(23)
    end == { :atomic, Database.Foo[id: 23, message: "yo dawg"] })
  end
end
