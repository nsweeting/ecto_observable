defmodule Ecto.Observable.TestRepo do
  use Ecto.Repo, otp_app: :ecto_observable
  use Ecto.Observable

  def init(_arg, config) do
    init_observable([Ecto.Observable.TestObserverThree])

    {:ok, config}
  end
end
