defmodule DunderMifflinBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :dunder_mifflin_bot,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DunderMifflinBot.Application, []}
    ]
  end

  defp deps do
    [
      {:nostrum, "~> 0.10"},
      {:req, "~> 0.5"},
      {:abacatepay_elixir_sdk, "~> 0.2"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18"},
      {:oban, "~> 2.18"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:dotenvy, "~> 0.8", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
