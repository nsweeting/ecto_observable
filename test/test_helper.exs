defmodule Observable.TestCase do
  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Observable.TestRepo)
  end
end

Observable.TestSupervisor.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Observable.TestRepo, :manual)

ExUnit.start()
