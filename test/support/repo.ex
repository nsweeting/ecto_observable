defmodule Observable.TestRepo do
  use Ecto.Repo, otp_app: :ecto_observable
  use Observable.Repo
end
