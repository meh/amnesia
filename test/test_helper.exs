defmodule Amnesia.Test do
  def start do
    :error_logger.tty(false)

    Amnesia.Schema.create
    Amnesia.start

    :ok
  end

  def stop do
    Amnesia.stop
    Amnesia.Schema.destroy

    :error_logger.tty(true)

    :ok
  end
end

ExUnit.start
