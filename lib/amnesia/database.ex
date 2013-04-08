#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Database do
  defmacro __using__(_opts) do
    quote do
      import Amnesia.Database

      Module.register_attribute __MODULE__, :tables, accumulate: true
    end
  end

  defmacro deffunctions do
    quote do
      def __tables__ do
        @tables
      end

      def create(copying // []) do
        Enum.map @tables, fn(table) ->
          table.create(copying)
        end
      end
    end
  end

  defmacro deftable(name, attributes, opts // [], do_block // []) do
    if opts[:do] do
      { opts, do_block } = { do_block, opts }
    end

    quote do
      defrecord unquote(name), unquote(attributes) do
        use Amnesia.Table

        deffunctions(unquote(name), unquote(opts))

        unquote(do_block)
      end

      @tables unquote(name)
    end
  end
end
