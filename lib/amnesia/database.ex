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

  defmodule Table do
    defmacro __using__(_opts) do
      quote do
        import Amnesia.Database.Table
      end
    end

    def create(name, definition // []) do
      :mnesia.create_table(name, definition)
    end

    def delete(name) do
      :mnesia.delete_table(name)
    end

    def clear(name) do
      :mnesia.clear_table(name)
    end

    def keys(name) do
      if Amnesia.Transaction.inside?
        :mnesia.all_keys(name)
      else
        :mnesia.dirty_all_keys(name)
      end
    end

    def mode(name, value) do
      :mnesia.change_table_access_mode(name, value)
    end

    def majority(name, value) do
      :mnesia.change_table_majority(name, value)
    end

    def priority(name, value) do
      :mnesia.change_table_load_order(name, value)
    end

    def copying(name, node, to) do
      :mnesia.change_table_copy_type(name, node, to)
    end
  end

  defmacro deftable(name, attributes, opts // [], do_block // []) do
    if opts[:do] do
      { opts, do_block } = { do_block, opts }
    end

    quote do
      defrecord unquote(name), unquote(attributes) do
        use Amnesia.Database.Table

        def __options__ do
          unquote(opts)
        end

        def create(copying // []) do
          create(unquote(name), [
            record_name: unquote(name),
            attributes:  List.Dict.keys(@record_fields),
            index:       unquote(opts[:indices]) || 1,

            type:        unquote(opts[:type])     || :set,
            access_mode: unquote(opts[:mode])     || :read_write,
            majority:    unquote(opts[:majority]) || false,
            load_order:  unquote(opts[:priority]) || 0
          ])
        end

        def delete do
          delete(unquote(name))
        end

        def clear do
          clear(unquote(name))
        end

        def keys do
          keys(unquote(name))
        end

        def mode(value) do
          mode(unquote(name), value)
        end

        def majority(value) do
          majority(unquote(name), value)
        end

        def priority(value) do
          priority(unquote(name), value)
        end

        def copying(node, to) do
          copying(unquote(name), node, to)
        end

        unquote(do_block)
      end

      @tables unquote(name)
    end
  end
end
