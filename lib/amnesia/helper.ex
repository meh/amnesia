#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Helper do
  defmodule Options do
    @doc """
    Allows use of pipe operator to chain conditional updates
    to a keyword list. If the given value is nil, no update is
    done.

    Please note: mylist[:a][:b] will properly return nil even
    of mylist[:a] is already nil instead of crashing. This allows
    using even deeply nested values safely with this construct.
    """
    def update(args, key, value) do
      case value do
        nil  -> args
        _any -> Keyword.put(args, key, value)
      end
    end

    @doc "Turns parameter into a list, invariant when paramers is a list or nil."
    def normalize(data) when data |> is_list do
      data
    end

    def normalize(nil), do: nil

    def normalize(data) do
      [data]
    end
  end

  defmacro result(result) do
    quote do
      result = try do
        unquote(result)
      catch
        :exit, error ->
          error
      end

      case result do
        { :atomic, result } ->
          result

        { :aborted, { :amnesia, { :cancel, result } } } ->
          result

        { :aborted, { exception, stacktrace } } ->
          reraise Exception.normalize(:error, exception), stacktrace

        { :aborted, error } ->
          throw error

        result ->
          result
      end
    end
  end
end
