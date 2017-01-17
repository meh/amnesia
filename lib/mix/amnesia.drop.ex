defmodule Mix.Tasks.Amnesia.Drop do
  use Mix.Task
  import Mix.Amnesia

  @shortdoc "Drop the storage for the given database"

  @doc false
  def run(args) do
    options = parse_args(args)
    db = ensure_database_module(options[:database])

    Amnesia.start
    db.wait
    db.destroy
    Amnesia.stop

    if options[:schema] do
      Amnesia.Schema.destroy
    end
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args, [
          aliases: [
            d: :database
          ],
          strict: [
            database: :string,
            schema: :boolean
          ]
        ])
    options
  end

end
