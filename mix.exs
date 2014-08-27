defmodule Amnesia.Mixfile do
  use Mix.Project

  def project do
    [ app: :amnesia,
      version: "0.2.0",
      elixir: "~> 0.15.0",
      deps: deps,
      package: package,
      description: "mnesia wrapper for Elixir" ]
  end

  def application do
    [ applications: [:mnesia, :logger] ]
  end

  defp deps do
    [ { :exquisite, "~> 0.1.2" },
      { :continuum, github: "meh/continuum" } ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/amnesia"} ]
  end
end
