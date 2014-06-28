Code.require_file "test_helper.exs", __DIR__

defmodule AmnesiaTest do
  use ExUnit.Case
  use Amnesia

  test "transaction returns proper values" do
    assert Amnesia.transaction(do: 42) == 42
  end

  test "transaction works with funs" do
    assert Amnesia.transaction(fn -> 42 end) == 42
  end

  test "transaction raises" do
    assert_raise RuntimeError, fn ->
      Amnesia.transaction do
        raise "herp"
      end
    end
  end

  setup_all do
    Amnesia.Test.start

    on_exit fn ->
      Amnesia.Test.stop
    end
  end
end
