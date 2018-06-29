defmodule Ecto.Observer do
  @moduledoc """
  Defines a new observer module for an `Ecto.Repo`.

  Observers are modules with a set of callbacks invoked during lifecyle events
  performed within a repo.

  The lifecyle events available are `:insert`, `:update`, and `:delete`. For
  each of these events, there is a corresponding `c:handle_insert/1`,
  `c:handle_update/2`, and `c:handle_delete/1` callback that can be invoked for
  an observer.

  Lets define an observer that will observe only `:insert` and `:update` events
  for a `Post` schema.

      defmodule MyObserver do
        use Ecto.Observer

        def observations do
          [
            {Post, :insert},
            {Post, :update}
          ]
        end

        def handle_insert(new_post) do
          :ok
        end

        def handle_update(old_post, new_post) do
          :ok
        end
      end

  The above callbacks will be invoked assuming we subscribe our observer to a
  given repo. For more information on subscribing to repos, as well as how to
  invoke the callbacks, please see `Ecto.Observable`.
  """

  @type t :: module | (Ecto.Observerable.action(), [Ecto.Schema.t()] -> any)

  @type observation :: {module, Ecto.Observerable.action()}

  @type observations :: [observation]

  @doc """
  Callback invoked for observers that subscribe to a repo schemas `:insert` action.

  The struct passed to the function will be the newly inserted record.

  This callback is only invoked on success.
  """
  @callback handle_insert(struct :: Ecto.Schema.t()) :: any

  @doc """
  Callback invoked for observers that subscribe to a repo schemas `:update` action.

  The callback will be passed both the old struct, as well as the newly updated
  one. This is useful for performing actions based on the difference bewteen
  the two.

  This callback is only invoked on success.
  """
  @callback handle_update(struct :: Ecto.Schema.t(), struct :: Ecto.Schema.t()) :: any

  @doc """
  Callback invoked for observers that subscribe to a repo schemas `:delete` action.

  The struct passed to the function will be the newly deleted record.

  This callback is only invoked on success.
  """
  @callback handle_delete(struct :: Ecto.Schema.t()) :: any

  @doc """
  Callback invoked to fetch the list of observations that this module wants to
  subscribe to.

  Below is an example of an observer that is subscribing to all `Post` lifecycle
  events.

  ## Example
      def observations do
        [
          {Post, :insert},
          {Post, :update},
          {Post, :delete}
        ]
      end
  """
  @callback observations() :: observations

  defmacro __using__(_opts) do
    quote do
      @behaviour Ecto.Observer

      def handle_insert(_struct) do
        :ok
      end

      def handle_update(_old_struct, _new_struct) do
        :ok
      end

      def handle_delete(_struct) do
        :ok
      end

      def observations do
        []
      end

      defoverridable Ecto.Observer
    end
  end
end
