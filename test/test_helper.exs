defmodule Ecto.Observable.TestCase do
  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ecto.Observable.TestRepo)
  end
end

Ecto.Observable.TestSupervisor.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Ecto.Observable.TestRepo, :manual)

ExUnit.start()
