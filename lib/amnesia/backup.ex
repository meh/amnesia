#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Backup do
  use Behaviour

  @type o :: { :ok, any } | { :error, any }
  @type i :: { :module, atom } | { :scope, :global | :local } | { :directory, String.t }
  @type r :: [{ :module, atom } |
              { :keep | :skip | :clear | :recreate, atom | [atom] } |
              { :default, :keep | :skip | :clear | :recreate }]

  @doc """
  Open the backup for writing.
  """
  defcallback open_write(any) :: o

  @doc """
  Write the given terms to the backup.
  """
  defcallback write(any, [any]) :: o

  @doc """
  Commit the write to the backup.
  """
  defcallback commit_write(any) :: o

  @doc """
  Close the backup if the backup is interrupted.
  """
  defcallback abort_write(any) :: o

  @doc """
  Open the backup for reading.
  """
  defcallback open_read(any) :: o

  @doc """
  Read terms from the backup.
  """
  defcallback read(any) :: { :ok, any, [any] } | { :error, any }

  @doc """
  Close the backup.
  """
  defcallback close_read(any) :: o

  @doc """
  Create a checkpoint, see `mnesia:activate_checkpoint`.
  """
  @spec checkpoint(Keyword.t) :: { :ok, any, [node] } | { :error, any }
  def checkpoint(options) do
    args = Keyword.new

    if options[:remote] do
      args = Keyword.put_new(args, :allow_remote, options[:remote])
    end

    :mnesia.activate_checkpoint(args)
  end

  @doc """
  Create a checkpoint with the given name, see `mnesia:activate_checkpoint`.
  """
  @spec checkpoint(any, Keyword.t) :: { :ok, any, [node] } | { :error, any }
  def checkpoint(name, options) do
    checkpoint(Keyword.put_new(options, :name, name))
  end

  @doc """
  Start a backup with the default backup module, see `mnesia:backup`.
  """
  @spec start(any) :: :ok | { :error, any }
  def start(data) do
    :mnesia.backup(data)
  end

  @doc """
  Start a backup of a given checkpoint, see `mnesia:backup_checkpoint`.
  """
  @spec start(any, any) :: :ok | { :error, any }
  def start(name, data) do
    :mnesia.backup_checkpoint(name, data)
  end

  @doc """
  Traverse a backup, see `mnesia:traverse_backup`.
  """
  @spec traverse(any, any, any, function) :: { :ok, any } | { :error, any }
  def traverse(source, target, acc, fun) do
    :mnesia.traverse_backup(source, target, fun, acc)
  end

  @doc """
  Traverse a backup with custom backup modules, see `mnesia:traverse_backup`.
  """
  @spec traverse(atom, any, atom, any, any, function) :: { :ok, any } | { :error, any }
  def traverse(source, source_data, target, target_data, acc, fun) do
    :mnesia.traverse_backup(source_data, source, target_data, target, fun, acc)
  end

  @doc false
  defp normalize(data) when is_list data do
    data
  end

  defp normalize(data) do
    [data]
  end

  @doc """
  Restore a backup, see `mnesia:restore`.
  """
  @spec restore(any, r) :: { :atomic, [atom] } | { :aborted, any }
  def restore(data, options) do
    args = Keyword.new

    if options[:module] do
      args = Keyword.put(args, :module, options[:module])
    end

    if options[:keep] do
      args = Keyword.put(args, :keep_tables, normalize(options[:keep]))
    end

    if options[:skip] do
      args = Keyword.put(args, :skip_tables, normalize(options[:keep]))
    end

    if options[:clear] do
      args = Keyword.put(args, :clear_tables, normalize(options[:clear]))
    end

    if options[:recreate] do
      args = Keyword.put(args, :recreate_tables, normalize(options[:recreate]))
    end

    if options[:default] do
      args = Keyword.put(args, :default, case options[:default] do
        :keep     -> :keep_tables
        :skip     -> :skip_tables
        :clear    -> :clear_tables
        :recreate -> :recreate_tables
      end)
    end

    :mnesia.restore(data, args)
  end

  @doc """
  Restore a backup with the given module, see `mnesia:restore`.
  """
  @spec restore(atom, any, r) :: { :atomic, [atom] } | { :aborted, any }
  def restore(module, data, options) do
    restore(data, Keyword.put(options, :module, module))
  end

  @doc """
  Install a fallback with the default backup module, see `mnesia:install_fallback`.
  """
  @spec install(any) :: :ok | { :error, any }
  def install(data) do
    :mnesia.install_fallback(data)
  end

  @doc """
  Install a fallback with the given backup module, see `mnesia:install_fallback`.
  """
  @spec install(atom | any) :: :ok | { :error, any }
  def install(module, data) do
    :mnesia.install_fallback(data, module)
  end

  @doc """
  Install a fallback with the given backup module and options, see `mnesia:install_fallback`.
  """
  @spec install(atom, any, i) :: :ok | { :error, any }
  def install(module, data, options) do
    args = [module: module]

    if options[:scope] do
      args = Keyword.put(args, :scope, options[:module])
    end

    if options[:directory] do
      args = Keyword.put(args, :mnesia_dir, options[:directory])
    end

    :mnesia.install_fallback(data, args)
  end

  @doc """
  Uninstall a fallback, see `mnesia:uninstall_fallback`.
  """
  @spec uninstall :: :ok | { :error, any }
  def uninstall do
    :mnesia.uninstall_fallback
  end

  @doc """
  Uninstall a fallback, see `mnesia:uninstall_fallback`.
  """
  @spec uninstall(i) :: :ok | { :error, any }
  def uninstall(options) do
    args = Keyword.new

    if options[:module] do
      args = Keyword.put(args, :module, options[:module])
    end

    if options[:scope] do
      args = Keyword.put(args, :scope, options[:module])
    end

    if options[:directory] do
      args = Keyword.put(args, :mnesia_dir, options[:directory])
    end

    :mnesia.uninstall_fallback(args)
  end

  @doc """
  Uninstall a fallback, see `mnesia:uninstall_fallback`.
  """
  @spec uninstall(atom, i) :: :ok | { :error, any }
  def uninstall(module, options) do
    uninstall(Keyword.put(options, :module, module))
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Amnesia.Backup

      @doc """
      Start a backup, see `mnesia:backup`.
      """
      @spec start(any) :: :ok | { :error, any }
      def start(data) do
        :mnesia.backup(data, __MODULE__)
      end

      @doc """
      Start a backup of the given checkpoint, see `mnesia:backup_checkpoint`.
      """
      @spec start(any, any) :: :ok | { :error, any }
      def start(name, data) do
        :mnesia.backup_checkpoint(name, data, __MODULE__)
      end

      @doc """
      Traverse a backup, see `mnesia:traverse_backup`.
      """
      @spec traverse(any, any, any, function) :: { :ok, any } | { :error, any }
      def traverse(data, target, acc, fun) do
        :mnesia.traverse_backup(data, __MODULE__, target, fun, acc)
      end

      @doc """
      Traverse a backup targeting a custom backup module, see
      `mnesia:traverse_backup`.
      """
      @spec traverse(any, atom, any, any, function) :: { :ok, any } | { :error, any }
      def traverse(data, target, target_data, acc, fun) do
        :mnesia.traverse_backup(data, target_data, target, fun, acc)
      end

      @doc """
      Restore a backup, see `mnesia:restore`.
      """
      @spec restore(any, Amnesia.Backup.r) :: { :atomic, [atom] } | { :aborted, any }
      def restore(data, options) do
        Amnesia.Backup.restore(__MODULE__, data, options)
      end

      @doc """
      Install a fallback, see `mnesia:install_fallback`.
      """
      @spec install(any) :: :ok | { :error, any }
      def install(data) do
        Amnesia.Backup.install(__MODULE__, data, [scope: :global])
      end

      @doc """
      Install a fallback, see `mnesia:install_fallback`.
      """
      @spec install(any, Amnesia.Backup.i) :: :ok | { :error, any }
      def install(data, options) do
        Amnesia.Backup.install(__MODULE__, data, options)
      end

      @doc """
      Uninstall a fallback, see `mnesia:uninstall_fallback`.
      """
      @spec uninstall :: :ok | { :error, any }
      def uninstall do
        Amnesia.Backup.uninstall(__MODULE__, [scope: :global])
      end

      @doc """
      Uninstall a fallback, see `mnesia:uninstall_fallback`.
      """
      @spec uninstall(atom, Amnesia.Backup.i) :: :ok | { :error, any }
      def uninstall(options) do
        Amnesia.Backup.uninstall(__MODULE__, options)
      end
    end
  end
end
