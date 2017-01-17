#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Fragment.Hash do
  @moduledoc """
  This module provides a behavior to implement a different fragment hashing
  algorithm.
  """

  @doc """
  Initialize the hash state.
  """
  @callback init_state(atom, any) :: any

  @doc """
  Add a fragment returning the new fragment numbers and state.
  """
  @callback add_frag(any) :: { any, [integer], [integer] }

  @doc """
  Delete a fragment returning the new fragment numbers and state.
  """
  @callback del_frag(any) :: { any, [integer], [integer] }

  @doc """
  Convert a key to a fragment number.
  """
  @callback key_to_frag_number(any, any) :: integer

  @doc """
  Convert a match_spec to fragment numbers.
  """
  @callback match_spec_to_frag_numbers(any, any) :: [integer]
end
