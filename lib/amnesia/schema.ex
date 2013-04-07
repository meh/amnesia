#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Schema do
  def print do
    :mnesia.schema
  end

  def print(tab) do
    :mnesia.schema(tab)
  end

  def create(nodes // [node]) do
    :mnesia.create_schema(nodes)
  end

  def delete(nodes // [node]) do
    :mnesia.delete_schema(nodes)
  end
end
