defmodule Amnesia.Mixfile do
  use Mix.Project

  def project do
    [ app: :amnesia,
      version: "0.2.7",
      deps: deps(),
      package: package(),
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
    [ { :exquisite, "~> 0.1.7" },
      { :ex_doc, "~> 0.15", only: [:dev] } ]
  end
end
