#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Event do
  defp handle([], fun) do
    receive do
      v -> fun.(v)
    end

    handle([], fun)
  end

  defp handle(categories, fun) do
    Enum.each categories, subscribe(&1)

    handle([], fun)
  end

  def observe(categories, fun) when is_list categories do
    spawn __MODULE__, :handle, [categories, fun]
  end

  def observe(category, fun) do
    observe([category], fun)
  end

  def subscribe(category) do
    :mnesia.subscribe(category)
  end

  def unsubscribe(category) do
    :mnesia.unsubscribe(category)
  end
end
