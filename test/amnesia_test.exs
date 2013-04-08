Code.require_file "../test_helper.exs", __FILE__

defmodule AmnesiaTest do
  use ExUnit.Case
  use Amnesia

  defdatabase Database do
    deftable Foo, [:id] do
      def bar do
        42
      end
    end
  end

  setup do
    start
  end

  test "transaction works" do
    assert transaction(do: 42) == { :atomic, 42 }
  end
end
