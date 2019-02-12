defmodule Observable.Repo do
  @moduledoc """
  Defines observable functionality for an `Ecto.Repo`.

  Observable functionality is defined as the ability to hook into the lifecyle
  of a struct to perform some kind of work based on the repo action performed.

  ## Setup

  Lets say we have a `Post` schema. Each post can have many topics. Users can
  subscribe to topics. Whenever a post is created,  we are responsible for informing
  the subscribed users.

  ### Repo

  Given the above, lets setup our new "observable" repo.

      defmodule Repo do
        use Ecto.Repo, otp_app: :my_app
        use Observable.Repo
      end

  We have defined our repo as normal - but with the addition of `use Observable.Repo`
  to bring in the required observable functionality.

  ### Observer

  Lets create our new observer now.

      defmodule SubscribersObserver do
        use Observable, :observer

        # Lets ignore posts that dont have any topics.
        def handle_notify(:insert, {_repo, _old, %Post{topics: []}) do
          :ok
        end

        def handle_notify(:insert, {_repo, _old, %Post{topics: topics}}) do
          # Do work required to inform subscribed users
        end
      end

  The response given by an observer must be one of three formats:

  * `:ok` - typically used when ignoring a notification.
  * `{:ok, result}` - a valid operation.
  * `{:error, result}` - an invalid operation that will trigger a transaction rollback.

  ### Schema

  Now that we have our observer set up, lets modify our Post schema to support
  notifying our observers.

      defmodule Post do
        use Ecto.Schema
        use Observable, :notifier

        schema "posts" do
          field(:title, :string)
          field(:body, :string)
          field(:topics, {:array, :string}, default: [])
        end

        observations do
          action(:insert, [SubscribersObserver])
        end
      end

  The actions must be either `:insert`, `:update`, or `:delete`. We can add as
  many observers to a given action as needed. Simply add them to the list. For
  example, we can define an observation for a `:delete` action - which will notify
  2 observers:

      action(:delete, [ObserverOne, ObserverTwo])

  ### Usage

  Now that we are starting to use "observable" behaviour, we must modify the way
  in which we insert posts with our repo.

      def create_post(params \\ %{}) do
        %Post{}
        |> Post.changeset(params)
        |> Repo.insert_and_notify()
      end

  Instead of the normal `c:Ecto.Repo.insert/2` function being called, we instead
  use `c:insert_and_notify/3`. This performs the exact same action as `c:Ecto.Repo.insert/2`
  (and returns the same results). The only change is the insert operation is done
  using an `Ecto.Multi` operation. Each observer is then added to the multi. The final multi
  is passed to a transaction. Any observer that fails, will fail the entire
  transaction.

  Lets say we want to let our users know when a posts topic changes to to something
  they have subscribed to. We must modify our observer for this functionality.

      def handle_notify(:update, {_repo, %Post{topics: old_topics}, %Post{topics: new_topics}})
          when old_topics != new_topics do
        # Get any additional topics and inform subscribed users.
      end

      # Define a "catch all"
      def handle_notify(_action, _data) do
        :ok
      end

  Now, lets modify our schema to reflect the updates to our observer.

        observations do
          action(:insert, [SubscribersObserver])
          action(:update, [SubscribersObserver])
        end

  Given the above, we can now notify users during updates.

      def update_post(post, params \\ %{}) do
        post
        |> Post.changeset(params)
        |> Repo.update_and_notify()
      end

  All of the functionality above can be carried over with a `action(:delete, [SubscribersObserver])`
  observation and the `c:delete_and_notify/3` function being invoked.
  """

  alias Ecto.Multi

  @doc """
  Inserts a struct defined via `Ecto.Schema` or a changeset and informs observers.

  Upon success, the repo, old struct and new struct are passed in the form -
  `{repo, old, new}` - to any observer that was assigned to observe the `:insert`
  action for the schema.

  This will return whatever response that `c:Ecto.Repo.insert/2` returns. Please
  see its documentation for further details.

  The `update_opts` are the options passed to the `Ecto.Multi.insert/2` operation.
  Since the entire operation is wrapped in a transaction, we can also pass
  `transaction_opts` which will be used with `c:Ecto.Repo.transaction/2`.

  Any observer must return a valid response as detailed in the "Observer" section above.
  """
  @callback insert_and_notify(
              struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
              insert_opts :: Keyword.t(),
              transaction_opts :: Keyword.t()
            ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Updates a changeset using its primary key and informs observers.

  Upon success, the repo, old struct and new struct are passed in the form -
  `{repo, old, new}` - to any observer that was assigned to observe the `:update`
  action for the schema.

  This will return whatever response that `c:Ecto.Repo.update/2` returns. Please
  see its documentation for further details.

  The `update_opts` are the options passed to the `Ecto.Multi.update/3` operation.
  Since the entire operation is wrapped in a transaction, we can also pass
  `transaction_opts` which will be used with `c:Ecto.Repo.transaction/2`.

  Any observer must return a valid response as detailed in the "Observer" section above.
  """
  @callback update_and_notify(
              changeset :: Ecto.Changeset.t(),
              update_opts :: Keyword.t(),
              transaction_opts :: Keyword.t()
            ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Deletes a struct using its primary key and informs observers.

  Upon success, the repo, old struct and new struct are passed in the form -
  `{repo, old, new}` - to any observer that was assigned to observe the `:delete`
  action for the schema.

  This will return whatever response that `c:Ecto.Repo.delete/2` returns. Please
  see its documentation for further details.

  The `delete_opts` are the options passed to the `Ecto.Multi.delete/2` operation.
  Since the entire operation is wrapped in a transaction, we can also pass
  `transaction_opts` which will be used with `c:Ecto.Repo.transaction/2`.

  Any observer must return a valid response as detailed in the "Observer" section above.
  """
  @callback delete_and_notify(
              struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
              delete_opts :: Keyword.t(),
              transaction_opts :: Keyword.t()
            ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Observable.Repo

      def insert_and_notify(changeset_or_schema, insert_opts \\ [], transaction_opts \\ []) do
        multi = Multi.new() |> Multi.insert(:data, changeset_or_schema, insert_opts)
        Observable.Repo.notify(__MODULE__, :insert, changeset_or_schema, multi, transaction_opts)
      end

      def update_and_notify(changeset, update_opts \\ [], transaction_opts \\ []) do
        multi = Multi.new() |> Multi.update(:data, changeset, update_opts)
        Observable.Repo.notify(__MODULE__, :update, changeset, multi, transaction_opts)
      end

      def delete_and_notify(changeset_or_schema, delete_opts \\ [], transaction_opts \\ []) do
        multi = Multi.new() |> Multi.delete(:data, changeset_or_schema, delete_opts)
        Observable.Repo.notify(__MODULE__, :delete, changeset_or_schema, multi, transaction_opts)
      end
    end
  end

  @doc false
  def notify(repo, action, changeset_or_schema, multi, opts \\ []) do
    old_data =
      case changeset_or_schema do
        %Ecto.Changeset{data: data} -> data
        other -> other
      end

    multi =
      old_data.__struct__
      |> Observable.observers(action)
      |> Enum.reduce(multi, fn observer, multi ->
        Multi.run(multi, :"#{observer}", fn repo, %{data: new_data} ->
          case Observable.notify_one(observer, action, {repo, old_data, new_data}) do
            :ok -> {:ok, nil}
            result -> result
          end
        end)
      end)

    case repo.transaction(multi, opts) do
      {:ok, %{data: data}} -> {:ok, data}
      {:error, _, error_value, _} -> {:error, error_value}
    end
  end
end
