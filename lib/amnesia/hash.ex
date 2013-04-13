#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Hash do
  use Behaviour

  @doc """
  Initialize the hash state.
  """
  defcallback init_state(atom, any) :: any

  @doc """
  Add a fragment returning the new fragment numbers and state.
  """
  defcallback add_frag(any) :: { any, [integer], [integer] }

  @doc """
  Delete a fragment returning the new fragment numbers and state.
  """
  defcallback del_frag(any) :: { any, [integer], [integer] }

  @doc """
  Convert a key to a fragment number.
  """
  defcallback key_to_frag_number(any, any) :: integer

  @doc """
  Convert a match_spec to fragment numbers.
  """
  defcallback match_spec_to_frag_numbers(any, any) :: [integer]
end
