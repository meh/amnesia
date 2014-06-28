Code.require_file "test_helper.exs", __DIR__

use Amnesia

defdatabase Test.Hooks.Database do
  deftable Foo, [:key, :value] do
    defhook write(%Foo{key: key}) when key == :wut do
      %Foo{key: :wut, value: 42}
    end

    defhook write(%Foo{key: key, value: value}) do
      %Foo{key: key, value: value * 2}
    end
  end
end

defmodule HooksTest do
  use ExUnit.Case
  use Test.Hooks.Database

  test "hooks work" do
    Amnesia.transaction! do
      assert %Foo{key: :lol, value: 2} |> Foo.write
    end

    assert(Amnesia.transaction do
      assert Foo.read(:lol).value == 4
    end == true)
  end

  test "when works in hooks" do
    Amnesia.transaction! do
      assert %Foo{key: :wut, value: 2} |> Foo.write
    end

    assert(Amnesia.transaction do
      assert Foo.read(:wut).value == 42
    end == true)
  end

  setup_all do
    Amnesia.Test.start

    on_exit fn ->
      Amnesia.Test.stop
    end
  end

  setup do
    Test.Hooks.Database.create!

    on_exit fn ->
      Test.Hooks.Database.destroy
    end
  end
end
