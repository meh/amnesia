#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Stream do
  defstruct table: nil, type: nil, lock: :read, dirty: false, reverse: false

  alias __MODULE__, as: S

  def new(name, type, options) do
    lock    = Keyword.get(options, :lock,    :read)
    dirty   = Keyword.get(options, :dirty,   false)
    reverse = Keyword.get(options, :reverse, false)

    stream = %S{table: name, type: type, lock: lock, dirty: dirty, reverse: reverse}

    if first(stream) do
      stream
    else
      []
    end
  end

  defp first(%S{table: table, dirty: false, reverse: false}) do
    table.first(true)
  end

  defp first(%S{table: table, dirty: false, reverse: true}) do
    table.last(true)
  end

  defp first(%S{table: table, dirty: true, reverse: false}) do
    table.first!(true)
  end

  defp first(%S{table: table, dirty: true, reverse: true}) do
    table.last!(true)
  end

  defp next(%S{table: table, dirty: false, reverse: false}, key) do
    table.next(key)
  end

  defp next(%S{table: table, dirty: false, reverse: true}, key) do
    table.prev(key)
  end

  defp next(%S{table: table, dirty: true, reverse: false}, key) do
    table.next!(key)
  end

  defp next(%S{table: table, dirty: true, reverse: true}, key) do
    table.prev!(key)
  end

  defp read(%S{table: table, dirty: false}, key) do
    table.read(key)
  end

  defp read(%S{table: table, dirty: true}, key) do
    table.read!(key)
  end

  @doc """
  Reverse the stream.
  """
  def reverse(%S{reverse: reverse} = self) do
    %S{self | reverse: not reverse}
  end

  @doc false
  def reduce(stream, acc, fun) do
    reduce(stream, first(stream), acc, fun)
  end

  defp reduce(_stream, _key, { :halt, acc }, _fun) do
    { :halted, acc }
  end

  defp reduce(stream, key, { :suspend, acc }, fun) do
    { :suspended, acc, &reduce(stream, key, &1, fun) }
  end

  defp reduce(_stream, nil, { :cont, acc }, _fun) do
    { :done, acc }
  end

  defp reduce(stream, key, { :cont, acc }, fun) do
    reduce(stream, next(stream, key), fun.(read(stream, key), acc), fun)
  end

  defimpl Enumerable do
    def reduce(stream, acc, fun) do
      Amnesia.Table.Stream.reduce(stream, acc, fun)
    end

    def count(_) do
      { :error, __MODULE__ }
    end

    def member?(_, _) do
      { :error, __MODULE__ }
    end
  end
end
