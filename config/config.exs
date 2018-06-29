# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env() == :test do
  config :ecto_observable, ecto_repos: [Ecto.Observable.TestRepo]

  config :ecto_observable, Ecto.Observable.TestRepo,
    adapter: Ecto.Adapters.Postgres,
    pool: Ecto.Adapters.SQL.Sandbox,
    database: "ecto_test",
    hostname: "localhost",
    username: "postgres",
    password: ""

  config :logger, :console, level: :error
end
