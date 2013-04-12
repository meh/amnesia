#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Fragment do
  @doc """
  Get the fragment properties of the given table.
  """
  @spec properties(atom) :: Keyword.t
  def properties(atom) do
    result     = Keyword.new
    properties = :mnesia.table_info(atom, :frag_properties)

    if number = properties[:n_fragments] do
      result = Keyword.put(result, :number, number)
    end

    if nodes = properties[:node_pool] do
      result = Keyword.put(result, :nodes, nodes)
    end

    if (key = properties[:foreign_key]) != :undefined do
      result = Keyword.put(result, :key, key)
    end

    if size = properties[:size] do
      result = Keyword.put(result, :size, size)
    end

    if memory = properties[:memory] do
      result = Keyword.put(result, :memory, memory)
    end

    result
  end

  @doc """
  Activate fragmentation on the given table, see `mnesia:change_table_frag`.
  """
  @spec activate(atom) :: Amnesia.Table.o
  def activate(name) do
    :mnesia.change_table_frag(name, { :activate, [] })
  end

  @doc """
  Activate fragmentation on the given tables on the given nodes, see
  `mnesia:change_table_frag`.
  """
  @spec activate(atom, [node]) :: Amnesia.Table.o
  def activate(name, nodes) do
    :mnesia.change_table_frag(name, { :activate, [node_pool: nodes] })
  end

  @doc """
  Deactivate fragmentation on the table, see `mnesia:change_table_frag`.
  """
  @spec deactivate(atom) :: Amnesia.Table.o
  def deactivate(name) do
    :mnesia.change_table_frag(name, :deactivate)
  end

  @doc """
  Add a fragment to the table on the given nodes, see
  `mnesia:change_table_frag`.
  """
  @spec add(atom, [node]) :: Amnesia.Table.o
  def add(name, nodes) do
    :mnesia.change_table_frag(name, { :add_frag, nodes })
  end

  @doc """
  Delete all fragments from the given table, see `mnesia:change_table_frag`.
  """
  @spec delete(atom) :: Amnesia.Table.o
  def delete(name) do
    :mnesia.change_table_frag(name, :del_frag)
  end

  @doc """
  Add a given node to the fragments of the given table, see
  `mnesia:change_table_frag`.
  """
  @spec add_node(atom, node) :: Amnesia.Table.o
  def add_node(name, node) do
    :mnesia.change_table_frag(name, { :add_node, node })
  end

  @doc """
  Delete a given node to the fragments of the given table, see
  `mnesia:change_table_frag`.
  """
  @spec delete_node(atom, node) :: Amnesia.Table.o
  def delete_node(name, node) do
    :mnesia.change_table_frag(name, { :del_node, node })
  end

  @doc """
  Start a transaction with the given block or function, see `mnesia:transaction`.
  """
  @spec transaction([] | function) :: { :aborted, any } | { :atomic, any }
  defmacro transaction(do: block) do
    quote do
      try do
        { :atomic, :mnesia.activity(:transaction, function(do: (() -> unquote(block))), [], :mnesia_frag) }
      catch
        :exit, error -> error
      end
    end
  end

  defmacro transaction(fun) when is_function fun, 0 do
    quote do
      try do
        { :atomic, :mnesia.activity(:transaction, unquote(fun), [], :mnesia_frag) }
      catch
        :exit, error -> error
      end
    end
  end

  @doc """
  Start a transaction with the given function passing the passed arguments to
  it, see `mnesia:transaction`.
  """
  @spec transaction(function, list) :: { :aborted, any } | { :atomic, any }
  def transaction(fun, args) when is_function fun, length args do
    try do
      { :atomic, :mnesia.activity(:transaction, fun, args, :mnesia_frag) }
    catch
      :exit, error -> error
    end
  end

  @doc """
  Start a transaction with the given function passing the passed arguments to it,
  trying to take a lock maximum *retries* times, see `mnesia:transaction`.
  """
  @spec transaction(function, list, integer) :: { :aborted, any } | { :atomic, any }
  def transaction(fun, args, retries) when is_function fun, length args do
    try do
      { :atomic, :mnesia.activity({ :transaction, retries }, fun, args, :mnesia_frag) }
    catch
      :exit, error -> error
    end
  end

  @doc """
  Start a synchronous transaction with the given block or function, see
  `mnesia:sync_transaction`.
  """
  @spec transaction!([] | function) :: { :aborted, any } | { :atomic, any }
  defmacro transaction!(do: block) do
    quote do
      try do
        { :atomic, :mnesia.activity(:sync_transaction, function(do: (() -> unquote(block))), [], :mnesia_frag) }
      catch
        :exit, error -> error
      end
    end
  end

  defmacro transaction!(fun) when is_function fun, 0 do
    quote do
      try do
        { :atomic, :mnesia.activity(:sync_transaction, unquote(fun), [], :mnesia_frag) }
      catch
        :exit, error -> error
      end
    end
  end

  @doc """
  Start a synchronous transaction with the given function passing the passed
  arguments to it, see `mnesia:sync_transaction`.
  """
  @spec transaction!(function, list) :: { :aborted, any} | { :atomic, any }
  def transaction!(fun, args) when is_function fun, length args do
    try do
      { :atomic, :mnesia.activity(:sync_transaction, fun, args, :mnesia_frag) }
    catch
      :exit, error -> error
    end
  end

  @doc """
  Start a synchronous transaction with the given function passing the passed
  arguments to it, trying to take a lock maximum *retries* times, see
  `mnesia:sync_transaction`.
  """
  @spec transaction!(function, list, integer) :: { :aborted, any } | { :atomic, any }
  def transaction!(fun, args, retries) when is_function fun, length args do
    try do
      { :atomic, :mnesia.activity({ :sync_transaction, retries }, fun, args, :mnesia_frag) }
    catch
      :exit, error -> error
    end
  end

  @doc """
  Run the passed function or block in the ETS context, see `mnesia:ets`.
  """
  @spec ets([] | function) :: any
  defmacro ets(do: block) do
    quote do
      :mnesia.activity(:ets, function(do: (() -> unquote(block))), [], :mnesia_frag)
    end
  end

  defmacro ets(fun) when is_function fun, 0 do
    quote do
      :mnesia.activity(:ets, unquote(fun), [], :mnesia_frag)
    end
  end

  @doc """
  Run the passed function in the ETS context passing over the passed arguments,
  see `mnesia:ets`.
  """
  @spec ets(function, list) :: any
  def ets(fun, args) when is_function fun, length args do
    :mnesia.activity(:ets, fun, args, :mnesia_frag)
  end

  @doc """
  Run the passed function or block in a dirty asynchronous context, see
  `mnesia:async_dirty`.
  """
  @spec async([] | function) :: any
  defmacro async(do: block) do
    quote do
      :mnesia.activity(:async_dirty, function(do: (() -> unquote(block))), [], :mnesia_frag)
    end
  end

  defmacro async(fun) when is_function fun, 0 do
    quote do
      :mnesia.activity(:async_dirty, unquote(fun), [], :mnesia_frag)
    end
  end

  @doc """
  Run the passed function in a dirty asynchronous context passing over the
  passed arguments, see `mnesia:async_dirty`.
  """
  @spec async(function, list) :: any
  def async(fun, args) when is_function fun, length args do
    :mnesia.activity(:async_dirty, fun, args, :mnesia_frag)
  end

  @doc """
  Run the passed function or block in a dirty synchronous context, see
  `mnesia:sync_dirty`.
  """
  @spec sync([] | function) :: any
  defmacro sync(do: block) do
    quote do
      :mnesia.activity(:sync_dirty, function(do: (() -> unquote(block))), [], :mnesia_frag)
    end
  end

  defmacro sync(fun) when is_function fun, 0 do
    quote do
      :mnesia.activity(:sync_dirty, unquote(fun), [], :mnesia_frag)
    end
  end

  @doc """
  Run the passed function in a dirty synchronous context passing over the
  passed arguments, see `mnesia:sync_dirty`.
  """
  @spec sync(function, list) :: any
  def sync(fun, args) when is_function fun, length args do
    :mnesia.activity(:sync_dirty, fun, args, :mnesia_frag)
  end
end
