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

  defmacro defdatabase!(name, do: block) do
    quote do
      defmodule unquote(name) do
        use Amnesia.Database

        unquote(block)

        def __tables__ do
          @tables
        end

        def create(copying // []) do
          Enum.map @tables, fn(table) ->
            table.create(copying)
          end
        end

        def destroy do
          Enum.map @tables, fn(table) ->
            table.destroy
          end
        end

        def wait(timeout // :infinity) do
          Amnesia.Table.wait(@tables, timeout)
        end
      end
    end
  end

  defmacro deftable(name, attributes, opts // [], do_block // []) do
    Amnesia.Table.deftable!(name, attributes, opts, do_block)
  end
end
