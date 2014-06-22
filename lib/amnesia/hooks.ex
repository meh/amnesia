defmodule Amnesia.Hooks do
  defmacro __using__(hooks) do
    [ quote(do: import Amnesia.Hooks),
      quote(do: @hooks unquote(hooks)) |

      Enum.map(hooks, fn { name, arity } ->
        args = Enum.map 1 .. arity, fn _ -> { :_, [], nil } end

        quote do
          def unquote("hook_#{name}" |> String.to_atom)(unquote_splicing(args)) do
            :undefined
          end

          defoverridable [{ unquote("hook_#{name}" |> String.to_atom), unquote(arity) }]
        end
      end) ]
  end

  defmacro defhook({ :when, _, [{ name, _, args }, guard] }, do: body) do
    quote do
      unless Enum.find @hooks, fn { name, arity } ->
        name == unquote(name) and arity == unquote(length(args))
      end do
        raise ArgumentError, message: "unknown #{unquote(name)} hook with #{unquote(length(args))} arity"
      end

      def unquote("hook_#{name}" |> String.to_atom)(unquote_splicing(args)) when unquote(guard) do
        unquote(body)
      end
    end
  end

  defmacro defhook({ name, _, args }, do: body) do
    quote do
      unless Enum.find @hooks, fn { name, arity } ->
        name == unquote(name) and arity == unquote(length(args))
      end do
        raise ArgumentError, message: "unknown #{unquote(name)} hook with #{unquote(length(args))} arity"
      end

      def unquote("hook_#{name}" |> String.to_atom)(unquote_splicing(args)) do
        unquote(body)
      end
    end
  end
end
