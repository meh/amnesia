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

  def create(copying // []) do

  end

  defmacro deftable(name, attributes, opts // [], do_block // []) do
    if opts[:do] do
      { opts, do_block } = { do_block, opts }
    end

    indices = if opts[:index] do
      [opts[:index]]
    else
      opts[:indices] || []
    end

    if indices == [1] do
      indices = []
    end

    quote do
      defrecord unquote(name), unquote(attributes) do
        def __options__ do
          unquote(opts)
        end

        def create(copying // []) do
          Table.create(unquote(name), [
            record_name: unquote(name),
            attributes:  List.Dict.keys(@record_fields),
            index:       unquote(indices),

            type:        unquote(opts[:type])     || :set,
            access_mode: unquote(opts[:mode])     || :read_write,
            majority:    unquote(opts[:majority]) || false,
            load_order:  unquote(opts[:priority]) || 0
          ])
        end

        def info(key) do
          Table.info(unquote(name), key)
        end

        def mode(value) do
          Table.mode(unquote(name), value)
        end

        def majority(value) do
          Table.majority(unquote(name), value)
        end

        def priority(value) do
          Table.priority(unquote(name), value)
        end

        def copying(node, to) do
          Table.copying(unquote(name), node, to)
        end

        def lock(mode) do
          Table.lock(unquote(name), mode)
        end

        def destroy do
          Table.destroy(unquote(name))
        end

        def clear do
          Table.clear(unquote(name))
        end

        def read(key, lock // :read) do
          Table.read(unquote(name), key, lock)
        end

        def read!(key) do
          Table.read!(unquote(name), key)
        end

        def keys do
          Table.keys(unquote(name))
        end

        def keys! do
          Table.keys!(unquote(name))
        end

        def first do
          Table.first(unquote(name))
        end

        def first! do
          Table.first!(unquote(name))
        end

        def key(self) do
          elem self, Enum.at!(unquote(indices), 0)
        end

        def next(self) do
          Table.next(unquote(name), self.key)
        end

        def next!(self) do
          Table.next!(unquote(name), self.key)
        end

        def prev(self) do
          Table.prev(unquote(name), self.key)
        end

        def prev!(self) do
          Table.prev!(unquote(name), self.key)
        end

        def last do
          Table.last(unquote(name))
        end

        def last! do
          Table.last!(unquote(name))
        end

        def delete(self) do
          :mnesia.delete_object(self)
        end

        def delete!(self) do
          :mnesia.dirty_delete_object(self)
        end

        def delete(key, self) do
          Table.delete(unquote(name), key)
        end

        def delete!(key, self) do
          Table.delete!(unquote(name), key)
        end

        def write(self) do
          :mnesia.write(self)
        end

        def write!(self) do
          :mnesia.dirty_write(self)
        end

        unquote(do_block)
      end

      @tables unquote(name)
    end
  end
end
