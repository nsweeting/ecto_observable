defmodule Ecto.Observable do
  @moduledoc """
  Defines observable functionality for an `Ecto.Repo`.

  Observable functionality is defined as the ability to hook into the lifecyle
  of a struct to perform some kind of work based on the repo action performed.

  Lets start of with an simple example. Lets say we have a `Post` schema.
  Each post can have many topics. Users can subscribe to a given topic. Whenever
  a post is created for a given topic, we are responsible for informing the
  subscribed users.

  Given the above, lets setup our new "observable" repo.

      defmodule Repo do
        use Ecto.Repo, otp_app: :my_app
        use Ecto.Observable

        @observers [SubscribersObserver]

        def init(_args, config) do
          init_observable(@observers)

          {:ok, config}
        end
      end

  We have defined our repo as normal - but with a few additions. First, we must
  `use Ecto.Observable` to bring in the required observable functionality. Second,
  from within our `c:Ecto.Repo.init/2` callback, we must invoke the `c:init_observable/1`
  function to setup our repo with the observers we want.

  Lets create our new observer now.

      defmodule SubscribersObserver do
        use Ecto.Observer

        def observations do
          [{Post, :insert}]
        end

        # Lets ignore posts that dont have any topics.
        def handle_insert(%Post{topics: []}) do
          :ok
        end

        def handle_insert(%Post{topics: topics}) do
          # Do work required to inform subscribed users.
        end
      end

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
  they have subscribed to. We must modify our oberver for this functionality.

        def observations do
          [
            {Post, :insert},
            {Post, :update}
          ]
        end

        def handle_update(%Post{topics: old_topics}, %Post{topics: new_topics})
            when old_topics != new_topics do
          # Get any additional topics and inform subscribed users.
        end

        # Define a "catch all"
        def handle_update(_old, _new) do
          :ok
        end

  Given the above, we can now notify users during updates.

      def update_post(post, params \\ %{}) do
        post
        |> Post.changeset(params)
        |> Repo.update_and_notify()
      end

  All of the functionality above can be carried over with a `{Post, :delete}`
  observation and the `c:delete_and_notify/2` function being invoked.

  ### Dynamic Observers

  We can dymnaically add, remove, and inspect observers of our repo if required.
  Please see the docs for `add_observer`, `delete_observer` and `get_observer`
  for further details.

  ### Function Observers

  Rather than defining module-based observers, we can also use function-based ones.
  Lets add some more oberservers to our repo `Post` schema.

      Repo.add_obeserver(fn action, [struct] -> :ok end, Post, :insert)
      Repo.add_obeserver(fn action, [old, new] -> :ok end, Post, :update)

  Now, whenever a `Post` is inserted or updated, our functions above will be
  invoked.
  """

  @type action :: :insert | :update | :delete

  @type observation :: Ecto.Observer.t() | {Ecto.Observer.t(), module, action}

  @type observations :: [observation]

  @doc """
  Returns the observers ETS table name tied to the repository.
  """
  @callback __observers__ :: atom

  @doc """
  A function that is required to be invoked within the `c:Ecto.Repo.init/2` callback.

  `Ecto.Observable` will not be able to function for your repo without this
  invoked.

  This will perform two actions:

  1. Sets up the ETS table used to store the observers of the repo.
  2. Adds the observers passed to the function so they will be ready when
  the repo is started.


  ## Example
      defmodule MyRepo do
        use Ecto.Repo, otp_app: :my_app
        use Ecto.Observable

        def init(_arg, config) do
          init_observable([MyObserver])

          {:ok, config}
        end
      end
  """
  @callback init_observable(observations) :: atom

  @doc """
  Inserts a struct defined via `Ecto.Schema` or a changeset and informs observers.

  Upon success, the newly insterted struct is passed to any `Ecto.Observable`
  that was assigned to observe the `:insert` action for the structs schema.

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

  Upon success, the old struct and updated struct are passed to any `Ecto.Observable`
  that was assigned to observe the `:update` action for the structs schema.

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

  Upon success, the deleted struct is passed to any `Ecto.Observable`
  that was assigned to observe the `:delete` action for the structs schema.

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

  @doc """
  Adds a new observer to the repo.

  This will use the callback defined in `c:Ecto.Observer.observations/0` to get
  all the observations defined within the observer module.

  Please see the docs for `Ecto.Observer` for more details on what an observer
  should look like.

  ## Example
      MyRepo.add_observer(Myobserver)
  """
  @callback add_observer(observer :: Ecto.Observer.t()) :: [boolean]

  @doc """
  Adds a new observer to the repo for the given struct and action.

  An action is simply an atom representation of the database operation being
  performed. This currently includes: `:insert`, `:update` or `:delete`.

  An observer is any `Ecto.Observer`. Observers can either be module or function
  based.

  Please see the docs for `Ecto.Observer` for more details on what an observer
  should look like.

  ## Example
      MyRepo.add_observer(Myobserver, Post, :insert)

      MyRepo.add_observer(fn action, [struct] -> :ok end, Post, :insert)
  """
  @callback add_observer(observer :: Ecto.Observer.t(), module, action) :: boolean

  @doc """
  Adds multiple observations to the repo.

  An action is simply an atom representation of the database operation being
  performed. This currently includes: `:insert`, `:update` or `:delete`.

  An observer is any `Ecto.Observer`. Observers can either be module or function
  based.

  Please see the docs for `Ecto.Observer` for more details on what an observer
  should look like.

  ## Example
      MyRepo.add_observer(Myobserver, Post, :insert)

      MyRepo.add_observer(fn action, [struct] -> :ok end, Post, :insert)
  """
  @callback add_observers(observations) :: [boolean | [boolean]]

  @doc """
  Gets all the observers of the repo for the given schema.
  """
  @callback get_observers(module) :: [{action, Ecto.Observer.t()}]

  @doc """
  Gets all the observers of the repo for the given schema and action.
  """
  @callback get_observers(module, action) :: [Ecto.Observer.t()]

  @doc """
  Deletes all observers of the repo.
  """
  @callback delete_observers() :: :ok

  @doc """
  Deletes all observers of the repo for the given schema.
  """
  @callback delete_observers(module) :: [{action, boolean}]

  @doc """
  Deletes all observers of the repo for the given schema and action.
  """
  @callback delete_observers(module, action) :: boolean

  @doc """
  Deletes a particular observers schema and action for the repo.
  """
  @callback delete_observer(observer :: Ecto.Observer.t(), module, action) :: boolean

  defmacro __using__(_opts) do
    quote do
      @behaviour Ecto.Observable

      @observers :"#{__MODULE__}.Observers"

      def __observers__ do
        @observers
      end

      def init_observable(observers \\ []) do
        Ecto.Observable.init_observable(__MODULE__, observers)
      end

      def insert_and_notify(struct, opts \\ []) do
        with {:ok, struct} <- insert(struct, opts) do
          Ecto.Observable.notify_observers(__MODULE__, :insert, [struct])
          {:ok, struct}
        end
      end

      def insert_and_notify!(struct, opts \\ []) do
        struct = insert!(struct, opts)
        Ecto.Observable.notify_observers(__MODULE__, :insert, [struct])
        struct
      end

      def update_and_notify(struct, opts \\ []) do
        with {:ok, new_struct} <- update(struct, opts) do
          Ecto.Observable.notify_observers(__MODULE__, :update, [struct.data, new_struct])
          {:ok, new_struct}
        end
      end

      def update_and_notify!(struct, opts \\ []) do
        new_struct = update!(struct, opts)
        Ecto.Observable.notify_observers(__MODULE__, :update, [struct.data, new_struct])
        new_struct
      end

      def delete_and_notify(struct, opts \\ []) do
        with {:ok, struct} <- delete(struct, opts) do
          Ecto.Observable.notify_observers(__MODULE__, :delete, [struct])
          {:ok, struct}
        end
      end

      def delete_and_notify!(struct, opts \\ []) do
        struct = delete!(struct, opts)
        Ecto.Observable.notify_observers(__MODULE__, :delete, [struct])
        struct
      end

      def add_observers(observers) do
        Ecto.Observable.add_observers(__MODULE__, observers)
      end

      def add_observer(observer) do
        Ecto.Observable.add_observer(__MODULE__, observer)
      end

      def add_observer(observer, schema, action) do
        Ecto.Observable.add_observer(__MODULE__, observer, schema, action)
      end

      def get_observers(schema) do
        Ecto.Observable.get_observers(__MODULE__, schema)
      end

      def get_observers(schema, action) do
        Ecto.Observable.get_observers(__MODULE__, schema, action)
      end

      def delete_observers do
        Ecto.Observable.delete_observers(__MODULE__)
      end

      def delete_observers(schema) do
        Ecto.Observable.delete_observers(__MODULE__, schema)
      end

      def delete_observers(schema, action) do
        Ecto.Observable.delete_observers(__MODULE__, schema, action)
      end

      def delete_observer(observer, schema, action) do
        Ecto.Observable.delete_observer(__MODULE__, observer, schema, action)
      end
    end
  end

  @doc false
  def init_observable(name, observers \\ []) do
    table = name.__observers__

    case :ets.info(table) do
      :undefined -> :ets.new(table, [:public, :named_table, {:read_concurrency, true}])
      _ -> table
    end

    add_observers(name, observers)

    :ok
  end

  @doc """
  Passes the provided structs to any observers that have subscribed to the given
  action and schema for the repo.

  Typically, the function does not need to be manually invoked. Please see
  `c:insert_and_notify/2`, `c:update_and_notify/2` or `c:delete_and_notify/2` for
  further details.

  ## Example
      MyRepo.add_observer(Myobserver, Post, :insert)
      MyRepo.add_observer(Myobserver, Post, :update)

      Ecto.Observable.notify_observers(MyRepo, :insert, [%Post{}])
      Ecto.Observable.notify_observers(MyRepo, :update, [%Post{}, %Post{}])
  """
  def notify_observers(name, action, [struct | _] = structs) do
    schema = struct.__struct__

    for observer <- get_observers(name, schema, action) do
      notify_observer(observer, action, structs)
    end
  end

  @doc false
  def notify_observer(observer, action, structs) when is_function(observer) do
    apply(observer, [action, structs])
  end

  @doc false
  def notify_observer(observer, action, structs) when is_atom(observer) do
    apply(observer, :"handle_#{action}", structs)
  end

  @doc false
  def add_observers(name, observers) do
    for observer <- observers do
      case observer do
        {observer, schema, action} -> add_observer(name, observer, schema, action)
        observer when is_atom(observer) -> add_observer(name, observer)
      end
    end
  end

  @doc false
  def add_observer(name, observer) do
    observations = observer.observations

    for {schema, action} <- observations do
      add_observer(name, observer, schema, action)
    end
  end

  @doc false
  def add_observer(name, observer, schema, action) do
    table = name.__observers__
    old_observers = get_observers(name, schema, action)
    new_observers = [observer | old_observers]

    :ets.insert(table, {{schema, action}, new_observers})
  end

  @doc false
  def get_observers(name, schema) do
    Enum.reduce([:delete, :update, :insert], [], fn action, results ->
      observers = get_observers(name, schema, action)
      [{action, observers} | results]
    end)
  end

  @doc false
  def get_observers(name, schema, action) do
    table = name.__observers__

    case :ets.lookup(table, {schema, action}) do
      [{_, observers}] -> observers
      _ -> []
    end
  end

  @doc false
  def delete_observers(name) do
    table = name.__observers__

    table
    |> :ets.tab2list()
    |> Enum.each(fn {{schema, action}, _} ->
      delete_observers(name, schema, action)
    end)
  end

  @doc false
  def delete_observers(name, schema) do
    for action <- [:delete, :update, :insert] do
      {action, delete_observers(name, schema, action)}
    end
  end

  @doc false
  def delete_observers(name, schema, action) do
    table = name.__observers__
    :ets.insert(table, {{schema, action}, []})
  end

  @doc false
  def delete_observer(name, observer, schema, action) do
    table = name.__observers__
    old_observers = get_observers(name, schema, action)
    new_observers = List.delete(old_observers, observer)

    :ets.insert(table, {{schema, action}, new_observers})
  end
end
