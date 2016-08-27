defmodule Amnesia.Mixfile do
  use Mix.Project

  def project do
    [ app: :amnesia,
      version: "0.2.5",
      deps: deps,
      package: package,
      description: "mnesia wrapper for Elixir" ]
  end

  defp package do
    [ maintainers: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/amnesia"} ]
  end

  def application do
    [ applications: [:mnesia, :logger, :exquisite] ]
  end

  defp deps do
    [ { :exquisite, "~> 0.1.6" },
      { :ex_doc, "~> 0.11", only: [:dev] } ]
  end
end
