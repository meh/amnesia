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
      import  Amnesia
      require Amnesia
    end
  end

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
    to_binary :mnesia.error_description(code)
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
  Check if it's inside a transaction or not, see `mnesia:is_transaction`.
  """
  @spec transaction? :: boolean
  def transaction? do
    :mnesia.is_transaction
  end

  @doc """
  Start a transaction with the given block or function, see `mnesia:transaction`.
  """
  @spec transaction([] | function) :: { :aborted, any } | { :atomic, any }
  defmacro transaction(do: block) do
    quote do
      :mnesia.transaction(function(do: (() -> unquote(block))))
    end
  end

  defmacro transaction(fun) when is_function fun, 0 do
    quote do
      :mnesia.transaction(unquote(fun))
    end
  end

  @doc """
  Start a transaction with the given function passing the passed arguments to
  it, see `mnesia:transaction`.
  """
  @spec transaction(function, list) :: { :aborted, any } | { :atomic, any }
  def transaction(fun, args) when is_function fun, length args do
    :mnesia.transaction(fun, args)
  end

  @doc """
  Start a transaction with the given function passing the passed arguments to it,
  trying to take a lock maximum *retries* times, see `mnesia:transaction`.
  """
  @spec transaction(function, list, integer) :: { :aborted, any } | { :atomic, any }
  def transaction(fun, args, retries) when is_function fun, length args do
    :mnesia.transaction(fun, args, retries)
  end

  @doc """
  Start a synchronous transaction with the given block or function, see
  `mnesia:sync_transaction`.
  """
  @spec transaction!([] | function) :: { :aborted, any } | { :atomic, any }
  defmacro transaction!(do: block) do
    quote do
      :mnesia.sync_transaction(function(do: (() -> unquote(block))))
    end
  end

  defmacro transaction!(fun) when is_function fun, 0 do
    quote do
      :mnesia.sync_transaction(unquote(fun))
    end
  end

  @doc """
  Start a synchronous transaction with the given function passing the passed
  arguments to it, see `mnesia:sync_transaction`.
  """
  @spec transaction!(function, list) :: { :aborted, any} | { :atomic, any }
  def transaction!(fun, args) when is_function fun, length args do
    :mnesia.sync_transaction(fun, args)
  end

  @doc """
  Start a synchronous transaction with the given function passing the passed
  arguments to it, trying to take a lock maximum *retries* times, see
  `mnesia:sync_transaction`.
  """
  @spec transaction!(function, list, integer) :: { :aborted, any } | { :atomic, any }
  def transaction!(fun, args, retries) when is_function fun, length args do
    :mnesia.sync_transaction(fun, args, retries)
  end

  @doc """
  Run the passed function or block in the ETS context, see `mnesia:ets`.
  """
  @spec ets([] | function) :: any
  defmacro ets(do: block) do
    quote do
      :mnesia.ets(function(do: (() -> unquote(block))))
    end
  end

  defmacro ets(fun) when is_function fun, 0 do
    quote do
      :mnesia.ets(unquote(fun))
    end
  end

  @doc """
  Run the passed function in the ETS context passing over the passed arguments,
  see `mnesia:ets`.
  """
  @spec ets(function, list) :: any
  def ets(fun, args) when is_function fun, length args do
    :mnesia.ets(fun, args)
  end

  @doc """
  Run the passed function or block in a dirty asynchronous context, see
  `mnesia:async_dirty`.
  """
  @spec async([] | function) :: any
  defmacro async(do: block) do
    quote do
      :mnesia.async_dirty(function(do: (() -> unquote(block))))
    end
  end

  defmacro async(fun) when is_function fun, 0 do
    quote do
      :mnesia.async_dirty(unquote(fun))
    end
  end

  @doc """
  Run the passed function in a dirty asynchronous context passing over the
  passed arguments, see `mnesia:async_dirty`.
  """
  @spec async(function, list) :: any
  def async(fun, args) when is_function fun, length args do
    :mnesia.async_dirty(fun, args)
  end

  @doc """
  Run the passed function or block in a dirty synchronous context, see
  `mnesia:sync_dirty`.
  """
  @spec sync([] | function) :: any
  defmacro sync(do: block) do
    quote do
      :mnesia.sync_dirty(function(do: (() -> unquote(block))))
    end
  end

  defmacro sync(fun) when is_function fun, 0 do
    quote do
      :mnesia.sync_dirty(unquote(fun))
    end
  end

  @doc """
  Run the passed function in a dirty synchronous context passing over the
  passed arguments, see `mnesia:sync_dirty`.
  """
  @spec sync(function, list) :: any
  def sync(fun, args) when is_function fun, length args do
    :mnesia.sync_dirty(fun, args)
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
