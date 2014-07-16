#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Select do
  defstruct values: [], continuation: nil, coerce: nil
  @opaque t :: %__MODULE__{}

  alias __MODULE__
  alias Amnesia.Selection

  @doc """
  Get a selection from the various select results.
  """
  @spec new(:'$end_of_table' | list | { list, any }) :: t | nil
  def new(value) do
    case value do
      :'$end_of_table' -> nil
      []               -> nil
      { [], _ }        -> nil

      { values, continuation } ->
        %Select{values: values, continuation: continuation}

      [_ | _] ->
        %Select{values: value}
    end
  end

  defimpl Selection do
    def coerce(selection, module) do
      %Select{selection | coerce: module}
    end

    def next(%Select{continuation: nil}) do
      nil
    end

    def next(%Select{continuation: c}) do
      Select.new(:mnesia.select(c))
    end

    def values(%Select{values: values, coerce: nil}) do
      values
    end

    def values(%Select{values: values, coerce: module}) do
      module.coerce(values)
    end
  end
end
