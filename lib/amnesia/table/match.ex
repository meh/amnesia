#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Match do
  defstruct values: [], coerce: nil
  @opaque t :: %__MODULE__{}

  alias __MODULE__
  alias Amnesia.Selection

  @doc """
  Get a match from the various match results.
  """
  @spec new([tuple]) :: t | nil
  def new(value) do
    case value do
      [] -> nil
      r  -> %Match{values: r}
    end
  end

  defimpl Selection do
    def coerce(match, module) do
      %Match{match | coerce: module}
    end

    def next(%Match{}) do
      nil
    end

    def values(%Match{values: values, coerce: nil}) do
      values
    end

    def values(%Match{values: values, coerce: module}) do
      module.coerce(values)
    end
  end
end
