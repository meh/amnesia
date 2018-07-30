#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Table.Definition do
  @doc false
  def where(module, attributes, options) do
    spec = { :{}, [], [module | for { key, _ } <- attributes do
      if options[:in] && options[:in][key] do
        { :in, [], [{ key, [], nil }, options[:in][key]] }
      else
        { key, [], nil }
      end
    end] }

    if options[:qualified] do
      qualifier = module |> to_string |> String.split(".") |> List.last
        |> String.replace(~r/([A-Z])/, "_\\1") |> String.slice(1, 255)
        |> String.downcase |> String.to_atom

      quote do: Exquisite.match(unquote({ qualifier, [], nil }) in unquote(spec),
        unquote(options))
    else
      quote do: Exquisite.match(unquote(spec), unquote(options))
    end
  end

  @doc false
  def match(module, pattern) do
    [module | for { key, _ } <- module.attributes do
      if Keyword.has_key?(pattern, key), do: pattern[key], else: :_
    end] |> List.to_tuple
  end

  @doc false
  def autoincrement(module, database, attributes, record) do
    alias Amnesia.Metadata, as: M

    Enum.reduce attributes, record, fn field, record ->
      if record |> Map.get(field) |> is_nil do
        record |> Map.put(field, database.metadata() |> M.counter(module, field, +1))
      else
        record
      end
    end
  end

  @doc false
  def attributes(attributes, options, index, copying) do
    Keyword.merge(options, [
      attributes: Keyword.keys(attributes),
      copying:    copying,
      index:      index
    ])
  end

  @doc false
  def define(database, name, attributes, opts \\ []) do
    if length(attributes) <= 1 do
      raise ArgumentError, message: "the table attributes must be more than 1"
    end

    block = Keyword.get(opts, :do, nil)
    opts  = Keyword.delete(opts, :do)
    index = Keyword.get(opts, :index, [])

    { autoincrement, attributes } = Enum.reduce attributes, { [], [] }, fn
      { name, { :autoincrement, _, _ } }, { autoincrement, attributes } ->
        { [name | autoincrement], attributes ++ [{ name, nil }] }

      { name, value }, { autoincrement, attributes } ->
        { autoincrement, attributes ++ [{ name, value }] }

      name, { autoincrement, attributes } ->
        { autoincrement, attributes ++ [{ name, nil }] }
    end

    quote do
      defmodule unquote(name) do
        defstruct unquote(attributes)

        use Amnesia.Hooks, write: 1, write!: 1, read: 2, read!: 2
        require Exquisite

        alias Amnesia.Table, as: T
        alias Amnesia.Table.Definition, as: D
        alias Amnesia.Selection, as: S

        @type autoincrement :: non_neg_integer

        @database      unquote(database)
        @options       unquote(opts)
        @autoincrement unquote(autoincrement)
        @attributes    unquote(attributes)
        @index         unquote(index)

        @doc """
        Require the needed modules to use the table effectively.
        """
        defmacro __using__(_opts) do
          quote do
            require Exquisite
            require unquote(__MODULE__)
          end
        end

        @doc """
        Return the database the table belongs to.
        """
        @spec database :: module
        def database do
          @database
        end

        @doc """
        The options passed when the table was defined.
        """
        @spec options :: Keyword.t
        def options do
          @options
        end

        @doc """
        The in order keyword list of attributes passed when the table was defined.
        """
        @spec attributes :: Keyword.t
        def attributes do
          @attributes
        end

        @doc """
        Get the name of the id key.
        """
        @spec id :: atom
        def id do
          unquote(attributes |> Enum.at(0) |> elem(0))
        end

        @doc false
        def coerce(unquote({ :%, [], [{ :__MODULE__, [], nil }, { :%{}, [],
          for { key, _ } <- attributes do
            { key, { key, [], nil } }
          end
        }] })) do
          unquote({ :{}, [], [name |
            for { key, _ } <- attributes do
              { key, [], nil }
            end
          ] })
        end

        def coerce(unquote({ :{}, [], [name |
          for { key, _ } <- attributes do
            { key, [], nil }
          end
        ] })) do
          unquote({ :%, [], [{ :__MODULE__, [], nil }, { :%{}, [],
            for { key, _ } <- attributes do
              { key, { key, [], nil } }
            end
          }] })
        end

        def coerce(list) when list |> is_list do
          Enum.map(list, &coerce/1)
        end

        def coerce(value) do
          value
        end

        @doc """
        Wait for the table optionally with a timeout.
        """
        @spec wait :: :ok | { :timeout, [atom] } | { :error, atom }
        @spec wait(integer | :infinity) :: :ok | { :timeout, [atom] } | { :error, atom }
        def wait(timeout \\ :infinity) do
          T.wait([__MODULE__], timeout)
        end

        @doc """
        Force load the table.
        """
        @spec force :: :yes | { :error, any }
        def force do
          T.force(__MODULE__)
        end

        @doc """
        Create the table with the given copying mode and inherent definition.
        """
        @spec create :: Amnesia.o
        @spec create(T.c) :: Amnesia.o
        def create(copying \\ []) do
          T.create(__MODULE__, D.attributes(@attributes, @options, @index, copying))
        end

        @spec create! :: :ok | no_return
        @spec create!(T.c) :: :ok | no_return
        def create!(copying \\ []) do
          T.create!(__MODULE__, D.attributes(@attributes, @options, @index, copying))
        end

        @doc """
        Return the type of the table.
        """
        @spec type(t) :: :set | :ordered_set | :bag
        def type(self) do
          @options[:type]
        end

        @doc """
        Check if the table is a bag.
        """
        @spec bag? :: boolean
        def bag? do
          @options[:type] == :bag
        end

        @doc """
        Check if the table is a set.
        """
        @spec set? :: boolean
        def set? do
          (@options[:type] || :set) == :set
        end

        @doc """
        Check if the table is an ordered set.
        """
        @spec ordered_set? :: boolean
        def ordered_set? do
          @options[:type] == :ordered_set
        end

        @doc """
        Get information about the table, see `mnesia:table_info`.
        """
        @spec info(atom) :: any
        def info(key) do
          T.info(__MODULE__, key)
        end

        @doc """
        Return properties of the table.
        """
        @spec properties :: Keyword.t
        def properties do
          T.properties(__MODULE__)
        end

        @doc """
        Change the access of the table, see `mnesia:change_table_access_mode`.

        ## Modes

        * `:both` sets read and write mode, it's the default.
        * `:read!` sets read-only mode.
        """
        @spec mode(:both | :read!) :: T.o
        def mode(value) do
          T.mode(__MODULE__, value)
        end

        @doc """
        Change the copying mode of the table on the given node, see
        `mnesia:change_table_copy_type`.

        ## Modes

        * `:disk` sets `:disc_copies` mode
        * `:disk!` sets `:disc_only_copies` mode
        * `:memory` sets `:ram_copies` mode
        """
        @spec copying(node, T.cv) :: T.o
        def copying(node, to) do
          T.copying(__MODULE__, node, to)
        end

        @doc """
        Change the table loading priority.
        """
        @spec priority(integer) :: T.o
        def priority(value) do
          T.priority(__MODULE__, value)
        end

        @doc """
        Change the table majority.
        """
        @spec majority(boolean) :: T.o
        def majority(value) do
          T.majority(__MODULE__, value)
        end

        @doc """
        Add a copy of the table on the given node with the given mode.
        """
        @spec add_copy(node) :: T.o
        @spec add_copy(node, T.cv) :: T.o
        def add_copy(node, type \\ :disk) do
          T.add_copy(__MODULE__, node, type)
        end

        @doc """
        Move a copy of the table from the given node to another given node.
        """
        @spec move_copy(node, node) :: T.o
        def move_copy(from, to) do
          T.move_copy(__MODULE__, from, to)
        end

        @doc """
        Delete a copy of the table from the given node.
        """
        @spec delete_copy(node) :: T.o
        def delete_copy(node) do
          T.delete_copy(__MODULE__, node)
        end

        @doc """
        Add the index in the table for the given attribute.
        """
        @spec add_index(atom) :: T.o
        def add_index(attribute) do
          T.add_index(__MODULE__, attribute)
        end

        @doc """
        Delete the index in the table for the given attribute.
        """
        @spec delete_index(atom) :: T.o
        def delete_index(attribute) do
          T.delete_index(__MODULE__, attribute)
        end

        @doc """
        Set master nodes for the table, see `mnesia:set_master_nodes`.
        """
        @spec master_nodes([node]) :: :ok | { :error, any }
        def master_nodes(nodes) do
          T.master_nodes(__MODULE__, nodes)
        end

        @doc """
        Lock the table with the given lock.

        ## Locks

        * `:write` sets a `:write` lock
        * `:write!` sets a `:sticky_write` lock
        * `:read` sets a `:read` lock
        """
        @spec lock(:write | :write! | :read) :: [node] | :ok | no_return
        def lock(mode) do
          T.lock(__MODULE__, mode)
        end

        @doc """
        Destroy the table.
        """
        @spec destroy :: T.o
        def destroy do
          T.destroy(__MODULE__)
        end

        @doc """
        Destroy the table, raising if an error occurs.
        """
        @spec destroy! :: :ok | no_return
        def destroy! do
          T.destroy!(__MODULE__)
        end

        @doc """
        Clear the content of the table.
        """
        @spec clear :: T.o
        def clear do
          T.clear(__MODULE__)
        end

        @doc """
        Check if the key is present in the table.
        """
        @spec member?(any) :: boolean
        def member?(key) do
          T.member?(__MODULE__, key)
        end

        @doc """
        Get the number of records in the table.
        """
        @spec count :: non_neg_integer
        def count do
          T.count(__MODULE__)
        end

        if @options[:type] == :bag do
          @doc """
          Read records from the table with the given key and given lock, see
          `mnesia:read`.

          ## Locks

          * `:write` sets a `:write` lock
          * `:write!` sets a `:sticky_write` lock
          * `:read` sets a `:read` lock
          """
          @spec read(any) :: [t] | nil | no_return
          @spec read(any, :read | :write | :write!) :: [t] | nil | no_return
          def read(key, lock \\ :read) do
            records = coerce(T.read(__MODULE__, key, lock))

            case hook_read(key, records) do
              :undefined ->
                records

              updated ->
                updated
            end
          end

          @doc """
          Read records from the table, see `mnesia:dirty_read`.
          """
          @spec read!(any) :: [t] | nil | no_return
          def read!(key) do
            records = coerce(T.read!(__MODULE__, key))

            case hook_read!(key, records) do
              :undefined ->
                records

              updated ->
                updated
            end
          end
        else
          @doc """
          Read a record from the table with the given lock, see `mnesia:read`.

          Unlike `mnesia:read` this returns either the record or nil.

          ## Locks

          * `:write` sets a `:write` lock
          * `:write!` sets a `:sticky_write` lock
          * `:read` sets a `:read` lock
          """
          @spec read(any) :: t | nil | no_return
          @spec read(any, :read | :write | :write!) :: t | nil | no_return
          def read(key, lock \\ :read) do
            record = case T.read(__MODULE__, key, lock) do
              [r] -> coerce(r)
              _   -> nil
            end

            case hook_read(key, record) do
              :undefined ->
                record

              updated ->
                updated
            end
          end

          @doc """
          Read a record from the table, see `mnesia:dirty_read`.

          Unlike `mnesia:dirty_read` this returns either the record or nil.
          """
          @spec read!(any) :: t | nil | no_return
          def read!(key) do
            record = case T.read!(__MODULE__, key) do
              [r] -> coerce(r)
              _   -> nil
            end

            case hook_read!(key, record) do
              :undefined ->
                record

              updated ->
                updated
            end
          end
        end

        @doc """
        Read records from the table based on a secondary index given as position,
        see `mnesia:index_read`.
        """
        @spec read_at(any, integer | atom) :: [t] | nil | no_return
        def read_at(key, position) do
          coerce(T.read_at(__MODULE__, key, position))
        end

        @doc """
        Read records from the table based on a secondary index given as position,
        see `mnesia:dirty_index_read`.
        """
        @spec read_at!(any, integer | atom) :: [t] | nil | no_return
        def read_at!(key, position) do
          coerce(T.read_at!(__MODULE__, key, position))
        end

        @doc """
        Return all the keys in the table, see `mnesia:all_keys`.
        """
        @spec keys :: list | no_return
        def keys do
          T.keys(__MODULE__)
        end

        @doc """
        Return all keys in the table, see `mnesia:dirty_all_keys`.
        """
        @spec keys! :: list | no_return
        def keys! do
          T.keys!(__MODULE__)
        end

        @doc """
        Read a record based on a slot, see `mnesia:dirty_slot`.
        """
        @spec at!(integer) :: t | nil | no_return
        def at!(position) do
          T.at!(__MODULE__, position)
        end

        @doc """
        Return the key of the record.
        """
        @spec key(t) :: any
        def key(%__MODULE__{unquote(Enum.at(attributes, 0) |> elem(0)) => key}) do
          key
        end

        @doc """
        Return the first key or record in the table, see `mnesia:first`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec first                :: t | nil | no_return
        @spec first(boolean)       :: any | t | nil | no_return
        @spec first(boolean, atom) :: any | t | nil | no_return
        def first(key \\ false, lock \\ :read)

        def first(true, lock) do
          T.first(__MODULE__)
        end

        def first(false, lock) do
          read(T.first(__MODULE__), lock)
        end

        @doc """
        Return the first key or record in the table, see `mnesia:dirty_first`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec first!          :: any | t | nil | no_return
        @spec first!(boolean) :: any | t | nil | no_return
        def first!(key \\ false)

        def first!(false) do
          read!(T.first!(__MODULE__))
        end

        def first!(true) do
          T.first!(__MODULE__)
        end

        @doc """
        Return the next key or record in the table, see `mnesia:next`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the next record, if you're calling it directly
        on the module it will treat the argument as key to start from and
        return you the next key.
        """
        @spec next(any | t) :: any | t | nil | no_return
        def next(%__MODULE__{} = self) do
          read(T.next(__MODULE__, self |> key))
        end

        def next(key) do
          T.next(__MODULE__, key)
        end

        @doc """
        Return the next key or record in the table, see `mnesia:dirty_next`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the next record, if you're calling it directly
        on the module it will treat the argument as key to start from and
        return you the next key.
        """
        @spec next!(any | t) :: any | t | nil | no_return
        def next!(%__MODULE__{} = self) do
          read!(T.next!(__MODULE__, self |> key))
        end

        def next!(key) do
          T.next!(__MODULE__, key)
        end

        @doc """
        Return the previous key or record in the table, see `mnesia:prev`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the previous record, if you're calling it
        directly on the module it will treat the argument as key to start from
        and return you the previous key.
        """
        @spec prev(any | t) :: any | t | nil | no_return
        def prev(%__MODULE__{} = self) do
          read(T.prev(__MODULE__, self |> key))
        end

        def prev(key) do
          T.prev(__MODULE__, key)
        end

        @doc """
        Return the previous key or record in the table, see `mnesia:dirty_prev`.

        If you're calling this function from an instance of the table (a record
        in it), it will get you the previous record, if you're calling it
        directly on the module it will treat the argument as key to start from
        and return you the previous key.
        """
        @spec prev!(any | t) :: any | t | nil | no_return
        def prev!(%__MODULE__{} = self) do
          read!(T.prev!(__MODULE__, self |> key))
        end

        def prev!(key) do
          T.prev!(__MODULE__, key)
        end

        @doc """
        Return the last key or record in the table, see `mnesia:last`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec last                :: t | nil | no_return
        @spec last(boolean)       :: any | t | nil | no_return
        @spec last(boolean, atom) :: any | t | nil | no_return
        def last(key \\ false, lock \\ :read)

        def last(true, lock) do
          T.last(__MODULE__)
        end

        def last(false, lock) do
          read(T.last(__MODULE__), lock)
        end

        @doc """
        Return the last key or record in the table, see `mnesia:dirty_last`.

        By default it returns the record, if you want only the key pass true as
        first parameter.

        If the table is a bag, it will return a list of records.
        """
        @spec last!          :: any | t | nil | no_return
        @spec last!(boolean) :: any | t | nil | no_return
        def last!(key \\ false)

        def last!(false) do
          read!(T.last!(__MODULE__))
        end

        def last!(true) do
          T.last!(__MODULE__)
        end

        @doc """
        Select records in the table using a match_spec, see `mnesia:select`.
        """
        @spec select(any) :: T.Selection.t | nil | no_return
        def select(spec) do
          T.select(__MODULE__, spec)
        end

        @doc """
        Select records in the given table using a match_spec passing a limit or a
        lock kind, see `mnesia:select`.
        """
        @spec select(integer | :read | :write, any) :: T.Selection.t | nil | no_return
        def select(lock_or_limit, spec) do
          T.select(__MODULE__, lock_or_limit, spec)
        end

        @doc """
        Select records in the given table using a match_spec passing a limit and a
        lock kind, see `mnesia:select`.
        """
        @spec select(integer | :read | :write, integer | :read | :write, integer) :: T.Selection.t | nil | no_return
        def select(lock_or_limit, limit_or_lock, spec) do
          T.select(__MODULE__, lock_or_limit, limit_or_lock, spec)
        end

        @doc """
        Select records in the table using a match_spec, see
        `mnesia:dirty_select`.
        """
        @spec select!(any) :: Selection.t | nil | no_return
        def select!(spec) do
          T.select!(__MODULE__, spec)
        end

        @doc """
        Select records in the table using an Exquisite query, see
        `Exquisite.match/2` and `mnesia:select`.

        ## Options

          * `limit` - sets the count of elements to select in every continuation
          * `lock` - sets the kind of lock to use
          * `select` - Exquisite selector spec
          * `qualified` - whether to set a name for the record or not

        """
        defmacro where(spec, options \\ []) do
          options = Keyword.put(options, :where, spec)
          lock = options[:lock]
          limit = options[:limit]

          cond do
            lock || limit ->
              quote do: S.coerce(
                T.select(unquote(__MODULE__),
                         unquote(lock || limit),
                         unquote(D.where(__MODULE__, @attributes, options))),
                unquote(__MODULE__))

            lock && limit ->
              quote do: S.coerce(
                T.select(unquote(__MODULE__),
                         unquote(lock),
                         unquote(limit),
                         unquote(D.where(__MODULE__, @attributes, options))),
                unquote(__MODULE__))

            true ->
              quote do: S.coerce(
                T.select(unquote(__MODULE__),
                         unquote(D.where(__MODULE__, @attributes, options))),
                unquote(__MODULE__))
          end
        end

        @doc """
        Select records in the table using an Exquisite query, see
        `Exquisite.match/2` and `mnesia:dirty_select`.

        ## Options

          * `select` - Exquisite selector spec
          * `qualified` - whether to set a name for the record or not

        """
        defmacro where!(spec, options \\ []) do
          options = Keyword.put(options, :where, spec)

          quote do
            S.coerce(T.select!(unquote(__MODULE__),
              unquote(D.where(__MODULE__, @attributes, options))), unquote(__MODULE__))
          end
        end

        @doc """
        Select records in the table using simple don't care values, see
        `mnesia:match_object`.
        """
        @spec match(any)                 :: [t] | nil | no_return
        @spec match(:read | :write, any) :: [t] | nil | no_return
        def match(lock \\ :read, pattern) do
          T.match(__MODULE__, lock, D.match(__MODULE__, pattern))
            |> S.coerce(__MODULE__)
        end

        @doc """
        Select records in the table using simple don't care values, see
        `mnesia:dirty_match_object`.
        """
        @spec match!(any) :: [t] | nil | no_return
        def match!(pattern) do
          T.match!(__MODULE__, D.match(__MODULE__, pattern))
            |> S.coerce(__MODULE__)
        end

        @doc """
        Fold the whole table from the left, see `mnesia:foldl`.
        """
        @spec foldl(any, (t, any -> any)) :: any | no_return
        def foldl(acc, fun) do
          T.foldl(__MODULE__, acc, fun)
        end

        @doc """
        Fold the whole table from the right, see `mnesia:foldr`.
        """
        @spec foldr(any, (t, any -> any)) :: any | no_return
        def foldr(acc, fun) do
          T.foldr(__MODULE__, acc, fun)
        end

        @doc """
        Return an iterator to use with Enum functions.
        """
        @spec stream :: T.Stream.t
        @spec stream(:read | :write | :write!) :: T.Stream.t
        def stream(lock \\ :read) do
          T.stream(__MODULE__, lock)
        end

        @doc """
        Return an iterator to use with the Enum functions using dirty
        operations to retrieve information.
        """
        @spec stream! :: T.Stream.t
        def stream! do
          T.stream!(__MODULE__)
        end

        @doc """
        Delete the record or the given key from the table, see `mnesia:delete`
        and `mnesia:delete_object`.
        """
        @spec delete(any | t) :: :ok | no_return
        def delete(%__MODULE__{} = self) do
          delete(self, :write)
        end

        def delete(key) do
          delete(key, :write)
        end

        @doc """
        Delete the record or the given key from the table with the given lock,
        see `mnesia:delete` and `mnesia:delete_object`.

        ## Locks

        * `:write` sets a `:write` lock
        * `:write!` sets a `:sticky_write` lock
        """
        @spec delete(atom | any, t | atom) :: :ok | no_return
        def delete(%__MODULE__{} = self, lock) do
          :mnesia.delete_object(__MODULE__, coerce(self), case lock do
            :write  -> :write
            :write! -> :sticky_write
          end)
        end

        def delete(key, lock) do
          :mnesia.delete(__MODULE__, key, case lock do
            :write  -> :write
            :write! -> :sticky_write
          end)
        end

        @doc """
        Delete the record or the given key from the table, see
        `mnesia:dirty_delete` and `mnesia:dirty_delete_object`.
        """
        @spec delete!(t | any) :: :ok | no_return
        def delete!(%__MODULE__{} = self) do
          :mnesia.dirty_delete_object(__MODULE__, coerce(self))
        end

        def delete!(key) do
          T.delete!(__MODULE__, key)
        end

        @doc """
        Write the record to the table, see `mnesia:write`.

        Missing fields tagged as autoincrement will be incremented with the
        counter if `nil`.
        """
        @spec write(t) :: t | no_return
        def write(self, lock \\ :write) do
          self = D.autoincrement(__MODULE__, @database, @autoincrement, self)

          case hook_write(self) do
            :undefined ->
              T.write(__MODULE__, coerce(self), lock)
              self

            updated ->
              T.write(__MODULE__, coerce(updated), lock)
              updated
          end
        end

        @doc """
        Write the record to the table, see `mnesia:dirty_write`.

        Missing fields tagged as autoincrement will be incremented with the
        counter if `nil`.
        """
        @spec write!(t) :: t | no_return
        def write!(self) do
          self = D.autoincrement(__MODULE__, @database, @autoincrement, self)

          case hook_write!(self) do
            :undefined ->
              T.write!(__MODULE__, coerce(self))
              self

            updated ->
              T.write!(__MODULE__, coerce(updated))
              updated
          end
        end

        unquote(block)

        unless Kernel.Typespec.defines_type?(__MODULE__, {:t, 0}) do
          @opaque t :: %__MODULE__{}
        end
      end
    end
  end
end
