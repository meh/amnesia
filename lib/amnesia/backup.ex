#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Backup do
  use Behaviour

  @type o :: { :ok, any } | { :error, any }

  @doc """
  Open the backup for writing.
  """
  defcallback open_write(any) :: o

  @doc """
  Write the given terms to the backup.
  """
  defcallback write(any, [any]) :: o

  @doc """
  Commit the write to the backup.
  """
  defcallback commit_write(any) :: o

  @doc """
  Close the backup if the backup is interrupted.
  """
  defcallback abort_write(any) :: o

  @doc """
  Open the backup for reading.
  """
  defcallback open_read(any) :: o

  @doc """
  Read terms from the backup.
  """
  defcallback read(any) :: { :ok, any, [any] } | { :error, any }

  @doc """
  Close the backup.
  """
  defcallback close_read(any) :: o
end
