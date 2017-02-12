defmodule Mix.Tasks.Amnesia.Create do
  use Mix.Task
  import Mix.Amnesia

  @shortdoc "Create the storage for the given database"

  @doc false
  def run(args) do
    options = parse_args(args)
    copying = parse_copying(options)
    db = ensure_database_module(options[:database])

    if options[:schema] do
      Amnesia.Schema.create
    end

    Amnesia.start
    try do
      db.create!(copying)
      :ok = db.wait(15000)
    after
      Amnesia.stop
    end
  end

  defp parse_copying(options) do
    copying = Enum.reduce options, [], fn({key, val}, acc) ->
      case {key, val} do
        {:disk, true} ->
          Keyword.put acc, :disk, [node()]
        {:disk!, true} ->
          Keyword.put acc, :disk!, [node()]
        {:memory, true} ->
          Keyword.put acc, :memory, [node()]
        _ ->
          acc
      end
    end

    # defaults to disk
    if Enum.empty?(copying) do
      [disk: [node()]]
    else
      copying
    end
  end

  defp parse_args([]) do
    Mix.raise "No database option. Please provide one."
  end
  defp parse_args(args) when is_list(args) do
    {options, _, _} = OptionParser.parse(args, [
          aliases: [
            d: :database
          ],
          strict: [
            database: :string,
            schema: :boolean,
            disk: :boolean,
            disk!: :boolean,
            memory: :boolean
          ]
        ])

    unless options[:database] do
      Mix.raise "No database option. Please provide one."
    end

    if is_nil(options[:schema]) do
      Keyword.put(options, :schema, true)
    else
      options
    end
  end
end
