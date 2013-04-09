#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia do
  defmacro __using__(_opts) do
    quote do
      import  Amnesia
      require Amnesia
    end
  end

  def start do
    :mnesia.start
  end

  def stop do
    :mnesia.stop
  end

  def info do
    :mnesia.info
  end

  def info(key) do
    :mnesia.system_info(key)
  end

  def error(code) do
    to_binary :mnesia.error_description(code)
  end

  def load(path) do
    :mnesia.load_textfile(path)
  end

  def dump(path) do
    :mnesia.dump_to_textfile(path)
  end

  def transaction? do
    :mnesia.is_transaction
  end

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

  def transaction(fun, args) when is_function fun, length args do
    :mnesia.transaction(fun, args)
  end

  def transaction(fun, args, retries) when is_function fun, length args do
    :mnesia.transaction(fun, args, retries)
  end

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

  def transaction!(fun, args) when is_function fun, length args do
    :mnesia.sync_transaction(fun, args)
  end

  def transaction!(fun, args, retries) when is_function fun, length args do
    :mnesia.sync_transaction(fun, args, retries)
  end

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

  def ets(fun, args) when is_function fun, length args do
    :mnesia.ets(fun, args)
  end

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

  def async(fun, args) when is_function fun, length args do
    :mnesia.async_dirty(fun, args)
  end

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

  def sync(fun, args) when is_function fun, length args do
    :mnesia.sync_dirty(fun, args)
  end

  def lock(key, nodes, mode) do
    :mnesia.lock({ :global, key, nodes }, case mode do
      :write  -> :write
      :write! -> :sticky_write
      :read   -> :read
    end)
  end

  defmacro defdatabase(name, do: block) do
    quote do
      defmodule unquote(name) do
        use Amnesia.Database

        unquote(block)

        deffunctions
      end
    end
  end
end
