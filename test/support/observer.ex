defmodule Observable.TestObserver do
  defmacro __using__(_opts) do
    quote do
      use Observable, :observer

      def handle_notify({:insert, struct}) do
        send(self(), {__MODULE__, :insert, struct})
      end

      def handle_notify({:update, [old_struct, new_struct]}) do
        send(self(), {__MODULE__, :update, old_struct, new_struct})
      end

      def handle_notify({:delete, struct}) do
        send(self(), {__MODULE__, :delete, struct})
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
