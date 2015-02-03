defmodule Amnesia.Mixfile do
  use Mix.Project

  def project do
    [ app: :amnesia,
      version: "0.2.0",
      elixir: "~> 1.0.0-rc1",
      deps: deps,
      package: package,
      description: "mnesia wrapper for Elixir" ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/amnesia"} ]
  end

  def application do
    [ applications: [:mnesia, :logger] ]
  end

  defp deps do
    [ { :exquisite, "~> 0.1.4" } ]
  end
end
