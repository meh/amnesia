Code.require_file "../test_helper.exs", __FILE__

defmodule CounterTest do
  use ExUnit.Case

  test "creates it" do
    c = Amnesia.Counter.get(:foo)

    assert c.value! == 0
  end

  test "increases it by one" do
    c = Amnesia.Counter.get(:foo)

    c.increase!
    assert c.value! == 1

    c.increase!
    assert c.value! == 2
  end

  test "increases by more than one" do
    c = Amnesia.Counter.get(:foo)

    c.increase 5
    assert c.value! == 5

    c.increase 10
    assert c.value! == 15
  end

  test "clears the counter properly" do
    c = Amnesia.Counter.get(:foo)

    c.increase!
    assert c.value! == 1

    c.clear!
    assert c.value! == 0
  end

  setup_all do
    Amnesia.Test.start
  end

  teardown_all do
    Amnesia.Test.stop
  end

  teardown do
    Amnesia.Counter.destroy

    :ok
  end
end
