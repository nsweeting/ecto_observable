defmodule Ecto.Observable.TestObserver do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Observer

      def handle_insert(struct) do
        send(self(), {__MODULE__, :insert, struct})
      end

      def handle_update(old_struct, new_struct) do
        send(self(), {__MODULE__, :update, old_struct, new_struct})
      end

      def handle_delete(struct) do
        send(self(), {__MODULE__, :delete, struct})
      end
    end
  end
end

defmodule Ecto.Observable.TestObserverOne do
  use Ecto.Observable.TestObserver
end

defmodule Ecto.Observable.TestObserverTwo do
  use Ecto.Observable.TestObserver
end

defmodule Ecto.Observable.TestObserverThree do
  use Ecto.Observable.TestObserver

  def observations do
    [
      {Ecto.Observable.Post, :insert}
    ]
  end
end
