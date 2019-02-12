defmodule Observable.TestRepo do
  use Ecto.Repo, otp_app: :ecto_observable, adapter: Ecto.Adapters.Postgres
  use Observable.Repo
end
