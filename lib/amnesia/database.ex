#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Database do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import Amnesia.Database

      # this is needed to populate the tables present in the database
      # definition
      Module.register_attribute __MODULE__, :tables, accumulate: true
    end
  end

  @doc false
  def defdatabase!(name, do: block) do
    quote do
      defmodule unquote(name) do
        use Amnesia.Database

        unquote(block)

        @doc false
        @spec __tables__ :: [atom]
        def __tables__ do
          @tables
        end

        @doc """
        Create the database, it calls `.create` on every defined table.
        """
        @spec create(Amnesia.Table.c) :: [Amnesia.Table.o]
        def create(copying // []) do
          Enum.map @tables, fn(table) ->
            table.create(copying)
          end
        end

        @doc """
        Destroy the database, it calls `.destroy` on every defined table.
        """
        @spec destroy :: [Amnesia.Table.o]
        def destroy do
          Enum.map @tables, fn(table) ->
            table.destroy
          end
        end

        @doc """
        Wait for the database to be loaded.
        """
        @spec wait(integer | :infinity) :: :ok | { :timeout, [atom] } | { :error, atom }
        def wait(timeout // :infinity) do
          Amnesia.Table.wait(@tables, timeout)
        end
      end
    end
  end

  @doc """
  Define a table in the database with the given name, attributes and options.

  The created table will actually be a record, so you can define functions on
  it like you would normally do for a record, various helper methods are added
  by default.

  ## Options

  * `:indices` specifies a list of additional indices to use instead of the
    first attribute.
  * `:type` specifies the type of the table, it can be `:set`, `:ordered_set`
     and `:bag`, the default is `:set`
  * `:mode` specifies the access mode, it can be `:both` and `:read!`, the
    default is `:both`
  * `:majority` specifies the majority of the table, the default is `false`
  * `:priority` specifies the load priority of the table
  * `:local` specifies if the table is local, default is `false`

  ## Example

      use Amnesia

      defdatabase Foo do
        deftable Bar, [:id, :a], type: :bag

        deftable Baz, [:id, :a, :b] do
          def foo(self)
            42
          end
        end
      end

  """
  defmacro deftable(name, attributes, opts // [], do_block // []) do
    Amnesia.Table.deftable!(name, attributes, opts, do_block)
  end
end
