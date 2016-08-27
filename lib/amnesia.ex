#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import  Amnesia, only: [defdatabase: 2]
      require Amnesia
      require Amnesia.Fragment
      require Amnesia.Helper
    end
  end

  require Amnesia.Helper

  @doc """
  Start the database, see `mnesia:start`.
  """
  @spec start :: :ok | { :error, any }
  def start do
    :mnesia.start
  end

  @doc """
  Stop the database, see `mnesia:stop`.
  """
  @spec stop :: :stopped
  def stop do
    :mnesia.stop
  end

  @type debug_level :: :none | :verbose | :debug | :trace | false | true

  @doc """
  Change the debug level.
  """
  @spec debug(debug_level) :: debug_level
  def debug(level) do
    :mnesia.set_debug_level(level)
  end

  @doc """
  Print information about the mnesia database, see `mnesia:info`.
  """
  @spec info :: :ok
  def info do
    :mnesia.info
  end

  @doc """
  Return information about the running instance, see `mnesia:system_info`.
  """
  @spec info(atom) :: any
  def info(key) do
    :mnesia.system_info(key)
  end

  @doc """
  Get an error description from an error code, see `mnesia:error_description`.
  """
  @spec error(atom) :: String.t
  def error(code) do
    :mnesia.error_description(code) |> to_string
  end

  @doc """
  Load a dump from a text file, see `mnesia:load_textfile`.
  """
  @spec load(String.t) :: none
  def load(path) do
    :mnesia.load_textfile(path)
  end

  @doc """
  Dump the database to a text file, see `mnesia:dump_to_textfile`.
  """
  @spec dump(String.t) :: none
  def dump(path) do
    :mnesia.dump_to_textfile(path)
  end

  @doc """
  Set master nodes, see `mnesia:set_master_nodes`.
  """
  @spec master_nodes([node]) :: :ok | { :error, any }
  def master_nodes(nodes) do
    :mnesia.set_master_nodes(nodes)
  end

  @doc """
  Lock the whole database on the given node for the given keys with the given
  lock, see `mnesia:lock`.

  ## Locks

  * `:write` sets a `:write` lock
  * `:write!` sets a `:sticky_write` lock
  * `:read` sets a `:read` lock
  """
  @spec lock(atom, [node], :write | :write! | :read) :: [node] | :ok | no_return
  def lock(key, nodes, mode) do
    :mnesia.lock({ :global, key, nodes }, case mode do
      :write  -> :write
      :write! -> :sticky_write
      :read   -> :read
    end)
  end

  @doc """
  Check if it's inside a transaction or not, see `mnesia:is_transaction`.
  """
  @spec transaction? :: boolean
  def transaction? do
    :mnesia.is_transaction
  end

  @doc """
  Abort the current transaction.
  """
  @spec abort(any) :: no_return
  def abort(reason) do
    :mnesia.abort(reason)
  end

  @doc """
  Cancel the current transaction.
  """
  @spec cancel()    :: no_return
  @spec cancel(any) :: no_return
  def cancel(value \\ nil) do
    :mnesia.abort({ :amnesia, { :cancel, value } })
  end

  @doc """
  Start a transaction with the given block or function, see `mnesia:transaction`.
  """
  @spec transaction([do: term] | term) :: any | no_return
  defmacro transaction(do: block) do
    quote do
      Amnesia.Helper.result(:mnesia.transaction(fn -> unquote(block) end))
    end
  end

  defmacro transaction(term) do
    quote do
      Amnesia.Helper.result(:mnesia.transaction(unquote(term)))
    end
  end

  @doc """
  Start a transaction with the given function passing the passed arguments to
  it, see `mnesia:transaction`.
  """
  @spec transaction(function, list) :: any | no_return
  def transaction(fun, args) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.transaction(fun, args))
  end

  @doc """
  Start a transaction with the given function passing the passed arguments to it,
  trying to take a lock maximum *retries* times, see `mnesia:transaction`.
  """
  @spec transaction(function, list, integer) :: any | no_return
  def transaction(fun, args, retries) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.transaction(fun, args, retries))
  end

  @doc """
  Start a synchronous transaction with the given block or function, see
  `mnesia:sync_transaction`.
  """
  @spec transaction!([do: term] | term) :: any | no_return
  defmacro transaction!(do: block) do
    quote do
      Amnesia.Helper.result(:mnesia.sync_transaction(fn -> unquote(block) end))
    end
  end

  defmacro transaction!(term) do
    quote do
      Amnesia.Helper.result(:mnesia.sync_transaction(unquote(term)))
    end
  end

  @doc """
  Start a synchronous transaction with the given function passing the passed
  arguments to it, see `mnesia:sync_transaction`.
  """
  @spec transaction!(function, list) :: any | no_return
  def transaction!(fun, args) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.sync_transaction(fun, args))
  end

  @doc """
  Start a synchronous transaction with the given function passing the passed
  arguments to it, trying to take a lock maximum *retries* times, see
  `mnesia:sync_transaction`.
  """
  @spec transaction!(function, list, integer) :: any | no_return
  def transaction!(fun, args, retries) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.sync_transaction(fun, args, retries))
  end

  @doc """
  Run the passed function or block in the ETS context, see `mnesia:ets`.
  """
  @spec ets([do: term] | term) :: any
  defmacro ets(do: block) do
    quote do
      Amnesia.Helper.result(:mnesia.ets(fn -> unquote(block) end))
    end
  end

  defmacro ets(term) do
    quote do
      Amnesia.Helper.result(:mnesia.ets(unquote(term)))
    end
  end

  @doc """
  Run the passed function in the ETS context passing over the passed arguments,
  see `mnesia:ets`.
  """
  @spec ets(function, list) :: any
  def ets(fun, args) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.ets(fun, args))
  end

  @doc """
  Run the passed function or block in a dirty asynchronous context, see
  `mnesia:async_dirty`.
  """
  @spec async([do: term] | term) :: any
  defmacro async(do: block) do
    quote do
      Amnesia.Helper.result(:mnesia.async_dirty(fn -> unquote(block) end))
    end
  end

  defmacro async(term) do
    quote do
      Amnesia.Helper.result(:mnesia.async_dirty(unquote(term)))
    end
  end

  @doc """
  Run the passed function in a dirty asynchronous context passing over the
  passed arguments, see `mnesia:async_dirty`.
  """
  @spec async(function, list) :: any
  def async(fun, args) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.async_dirty(fun, args))
  end

  @doc """
  Run the passed function or block in a dirty synchronous context, see
  `mnesia:sync_dirty`.
  """
  @spec sync([do: term] | term) :: any
  defmacro sync(do: block) do
    quote do
      Amnesia.Helper.result(:mnesia.sync_dirty(fn -> unquote(block) end))
    end
  end

  defmacro sync(term) do
    quote do
      Amnesia.Helper.result(:mnesia.sync_dirty(unquote(term)))
    end
  end

  @doc """
  Run the passed function in a dirty synchronous context passing over the
  passed arguments, see `mnesia:sync_dirty`.
  """
  @spec sync(function, list) :: any
  def sync(fun, args) when is_function fun, length args do
    Amnesia.Helper.result(:mnesia.sync_dirty(fun, args))
  end

  @doc """
  Define a database with the given name and the various definitions in the
  block.

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
  defmacro defdatabase(name, do: block) do
    Amnesia.Database.defdatabase!(name, do: block)
  end
end
