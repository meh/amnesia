defmodule Amnesia.Test do
  def start do
    Logger.remove_backend :console

    Amnesia.Schema.create
    Amnesia.start

    :ok
  end

  def stop do
    Amnesia.stop
    Amnesia.Schema.destroy

    Logger.add_backend :console, flush: true

    :ok
  end
end

ExUnit.start
