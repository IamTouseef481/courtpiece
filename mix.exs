defmodule CourtPiece.MixProject do
  use Mix.Project

  def project do
    [
      app: :courtpiece,
      version: "0.1.0",
      elixir: "~> 1.14.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CourtPiece.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.15"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:bcrypt_elixir, ">= 0.0.0"},
      {:plug_cowboy, "~> 2.5"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev], runtime: false},
      {:git_hooks, "~> 0.7.3", only: [:dev], runtime: false},
      {:phoenix_swagger, "~> 0.8.3"},
      {:ex_json_schema, "~> 0.7.1"},
      {:httpoison, "~> 1.8.2"},
      {:sage, "~> 0.6.3"},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:faker, "~> 0.17.0", only: :test},
      {:cors_plug, "~> 3.0"},
      {:scrivener_ecto, "~> 2.7"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      check: ["format", "credo --strict", "compile --warnings-as-errors", "dialyzer"]
    ]
  end
end
