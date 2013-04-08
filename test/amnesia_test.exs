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

  setup do
    start

    Database.create

    :ok
  end

  test "saves item" do
    transaction! do
      Database.Foo[id: 23, message: "yo dawg"].write
    end

    transaction! do
      Database.Foo.read(23) == Database.Foo[id: 23, message: "yo dawg"]
    end
  end

  test "transaction works" do
    assert transaction(do: 42) == { :atomic, 42 }
  end
end
