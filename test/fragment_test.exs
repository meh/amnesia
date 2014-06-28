defmodule FragmentTest do
  use ExUnit.Case
  use Amnesia

  test "transaction returns proper values" do
    assert(Amnesia.Fragment.transaction do
      42
    end == 42)
  end

  test "transaction raises" do
    assert_raise RuntimeError, fn ->
      Amnesia.Fragment.transaction do
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
