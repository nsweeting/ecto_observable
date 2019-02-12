defmodule EctoObserverable.MixProject do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :ecto_observable,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      name: "Ecto Observable",
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

  defp aliases do
    [
      "db.reset": [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate"
      ]
    ]
  end

  defp description do
    """
    Ecto Observable brings observable functionality to an Ecto Repo.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Nicholas Sweeting"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nsweeting/ecto_observable"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: "https://github.com/nsweeting/ecto_observable"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:observable, "~> 0.3"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
