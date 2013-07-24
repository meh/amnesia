#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defexception Amnesia.TableExistsError, name: nil do
  def message(exception) do
    "Table #{inspect exception.name} already exists"
  end
end

defexception Amnesia.TableMissingError, name: nil do
  def message(exception) do
    "Table #{inspect exception.name} doesn't exists"
  end
end
