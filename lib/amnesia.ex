#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia do
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
    :mnesia.error_description(code)
  end

  def load(path) do
    :mnesia.load_textfile(path)
  end

  def dump(path) do
    :mnesia.dump_to_textfile(path)
  end

  defmacro defdatabase(name, do: block) do
    quote do
      defmodule unquote(name) do
        use Amnesia.Database

        unquote(block)

        def __tables__ do
          @tables
        end
      end
    end
  end
end
