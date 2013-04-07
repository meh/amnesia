Code.require_file "../test_helper.exs", __FILE__

defmodule AmnesiaTest do
  use    ExUnit.Case
  import Amnesia

  defdatabase Database do
    deftable Foo, [:id] do
      def bar do
        42
      end
    end
  end

  test "creates table properly" do
  end
end
