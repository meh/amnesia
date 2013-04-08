Code.require_file "../test_helper.exs", __FILE__

defmodule CounterTest do
  use ExUnit.Case

  setup do
    Amnesia.start
  end

  test "creates it" do
    c = Amnesia.Counter.create(:foo)

    assert c.value == 0
  end
end
