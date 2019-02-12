defmodule Observable.TestObserver do
  defmacro __using__(_opts) do
    quote do
      use Observable, :observer

      def handle_notify(:insert, {repo, old, new}) do
        {:ok, send(self(), {__MODULE__, :insert, repo, old, new})}
      end

      def handle_notify(:update, {repo, old, new}) do
        {:ok, send(self(), {__MODULE__, :update, repo, old, new})}
      end

      def handle_notify(:delete, {repo, old, new}) do
        {:ok, send(self(), {__MODULE__, :delete, repo, old, new})}
      end
    end
  end
end

defmodule Observable.TestObserverOne do
  use Observable.TestObserver
end

defmodule Observable.TestObserverTwo do
  use Observable.TestObserver
end

defmodule Observable.TestObserverThree do
  use Observable, :observer

  def handle_notify(_action, _data) do
    raise RuntimeError, "uh oh"
  end
end

defmodule Observable.TestObserverFour do
  use Observable, :observer

  def handle_notify(_action, _data) do
    {:error, %Ecto.Changeset{}}
  end
end
