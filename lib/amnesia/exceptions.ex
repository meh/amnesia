#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.TableExistsError do
  defexception message: nil

  def exception(name: name) do
    %__MODULE__{message: "Table #{inspect name} already exists"}
  end
end

defmodule Amnesia.TableMissingError do
  defexception message: nil

  def exception(name: name) do
    %__MODULE__{message: "Table #{inspect name} doesn't exists"}
  end
end
