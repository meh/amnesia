defmodule FragmentTest do
  use ExUnit.Case
  use Amnesia

  test "transaction returns proper values" do
    assert(Amnesia.Fragment.transaction do
      42
    end == { :atomic, 42 })

    assert(Amnesia.Fragment.transaction do
      exit :doo
    end == { :aborted, :doo })
  end

  setup_all do
    Amnesia.Test.start
  end

  teardown_all do
    Amnesia.Test.stop
  end
end
