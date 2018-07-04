defmodule Observable.Repo do
  @moduledoc """
  Defines observable functionality for an `Ecto.Repo`.

  Observable functionality is defined as the ability to hook into the lifecyle
  of a struct to perform some kind of work based on the repo action performed.

  Lets start of with an simple example. Lets say we have a `Post` schema. Each
  post can have many topics. Users can subscribe to topics. Whenever a post is created,
  we are responsible for informing the subscribed users.

  Given the above, lets setup our new "observable" repo.

      defmodule Repo do
        use Ecto.Repo, otp_app: :my_app
        use Observable.Repo
      end

  We have defined our repo as normal - but with the addition of `use Observable.Repo`
  to bring in the required observable functionality.

  Lets create our new observer now.

      defmodule SubscribersObserver do
        use Observable, :observer

        # Lets ignore posts that dont have any topics.
        def handle_notify({:insert, %Post{topics: []}}) do
          :ok
        end

        def handle_notify({:insert, %Post{topics: topics}}) do
          # Do work required to inform subscribed users.
        end
      end

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

  Now that we are starting to use "observable" behaviour, we must modify the way
  in which we insert posts with our repo.

      def create_post(params \\ %{}) do
        %Post{}
        |> Post.changeset(params)
        |> Repo.insert_and_notify()
      end

  Instead of the normal `Ecto.Repo.insert/2` function being called, we instead
  use `c:insert_and_notify/2`. This performs the exact same action as `Ecto.Repo.insert/2`
  (and returns the same results). The only change is that upon successful insertion
  to the database, our observers have their callbacks invoked.

  Lets say we want to let our users know when a posts topic changes to to something
  they have subscribed to. We must modify our observer for this functionality.

        def handle_notify({:update, [%Post{topics: old_topics}, %Post{topics: new_topics}]})
            when old_topics != new_topics do
          # Get any additional topics and inform subscribed users.
        end

        # Define a "catch all"
        def handle_notify(_) do
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
  observation and the `c:delete_and_notify/2` function being invoked.
  """

  @doc """
  Inserts a struct defined via `Ecto.Schema` or a changeset and informs observers.

  Upon success, the newly insterted struct is passed to any observer
  that was assigned to observe the `:insert` action for the schema. The operation
  is wrapped in a transaction and will rollback if any observer raises an error.

  This will return whatever response that `c:Ecto.Repo.insert/2` returns. Please
  see its documentation for further details.
  """
  @callback insert_and_notify(
              struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
              opts :: Keyword.t()
            ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Same as `c:insert_and_notify/2` but returns the struct or raises if the changeset is invalid.
  """
  @callback insert_and_notify!(
              struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
              opts :: Keyword.t()
            ) :: Ecto.Schema.t() | no_return

  @doc """
  Updates a changeset using its primary key and informs observers.

  Upon success, the old struct and updated struct are passed in list form -
  `[old_struct, updated_struct]` - to any observer that was assigned to observe
  the `:update` action for the schema. The operation is wrapped in a transaction
  and will rollback if any observer raises an error.

  This will return whatever response that `c:Ecto.Repo.update/2` returns. Please
  see its documentation for further details.
  """
  @callback update_and_notify(changeset :: Ecto.Changeset.t(), opts :: Keyword.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Same as `c:update_and_notify/2` but returns the struct or raises if the changeset is invalid.
  """
  @callback update_and_notify!(changeset :: Ecto.Changeset.t(), opts :: Keyword.t()) ::
              {:ok, Ecto.Schema.t()} | no_return

  @doc """
  Deletes a struct using its primary key and informs observers.

  Upon success, the deleted struct is passed to any observer
  that was assigned to observe the `:delete` action for the schema. The operation
  is wrapped in a transaction and will rollback if any observer raises an error.

  This will return whatever response that `c:Ecto.Repo.delete/2` returns. Please
  see its documentation for further details.
  """
  @callback delete_and_notify(
              struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
              opts :: Keyword.t()
            ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Same as `c:delete_and_notify/2` but returns the struct or raises if the changeset is invalid.
  """
  @callback delete_and_notify!(
              struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
              opts :: Keyword.t()
            ) :: {:ok, Ecto.Schema.t()} | no_return

  defmacro __using__(_opts) do
    quote do
      @behaviour Observable.Repo

      def insert_and_notify(struct, opts \\ []) do
        fn ->
          with {:ok, struct} <- insert(struct, opts) do
            Observable.notify(struct, :insert)
            {:ok, struct}
          end
        end
        |> transaction()
        |> elem(1)
      end

      def insert_and_notify!(struct, opts \\ []) do
        fn ->
          struct = insert!(struct, opts)
          Observable.notify(struct, :insert)
          struct
        end
        |> transaction()
        |> elem(1)
      end

      def update_and_notify(struct, opts \\ []) do
        fn ->
          with {:ok, new_struct} <- update(struct, opts) do
            Observable.notify([struct.data, new_struct], :update)
            {:ok, new_struct}
          end
        end
        |> transaction()
        |> elem(1)
      end

      def update_and_notify!(struct, opts \\ []) do
        fn ->
          new_struct = update!(struct, opts)
          Observable.notify([struct.data, new_struct], :update)
          new_struct
        end
        |> transaction()
        |> elem(1)
      end

      def delete_and_notify(struct, opts \\ []) do
        fn ->
          with {:ok, struct} <- delete(struct, opts) do
            Observable.notify(struct, :delete)
            {:ok, struct}
          end
        end
        |> transaction()
        |> elem(1)
      end

      def delete_and_notify!(struct, opts \\ []) do
        fn ->
          struct = delete!(struct, opts)
          Observable.notify(struct, :delete)
          struct
        end
        |> transaction()
        |> elem(1)
      end
    end
  end
end
