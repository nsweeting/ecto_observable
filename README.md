# Ecto.Observer

`Ecto.Observer` adds "observable" functionality to `Ecto.Repo`.

## Installation

The package can be installed by adding `ecto_observer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_observer, "~> 0.1.0"}
  ]
end
```
## Documentation

See [HexDocs](https://hexdocs.pm/ecto_observer) for additional documentation.

## Getting Started

Lets say we have a `Post` schema. Each post can have many topics. Users can
subscribe to a given topic. Whenever a post is created for a given topic, we
are responsible for informing the subscribed users.


Given the above, lets setup our new "observable" repo.

```elixir
defmodule Repo do
  use Ecto.Repo, otp_app: :my_app
  use Ecto.Observable

  @observers [SubscribersObserver]

  def init(_args, config) do
    init_observable(@observers)

    {:ok, config}
  end
end
```

We have defined our repo as normal - but with a few additions. First, we must
`use Ecto.Observable` to bring in the required observable functionality. Second,
from within our `Ecto.Repo.init/2` callback, we must invoke the `Ecto.Observable.init_observable/1`
function to setup our repo with the observers we want.

Lets create our new observer now.

```elixir
defmodule SubscribersObserver do
  use Ecto.Observer

  def observations do
    [
      {Post, :insert},
      {Post, :update} # Defined for the sake of example. Ignore me!
    ]
  end

  # Lets ignore posts that dont have any topics.
  def handle_insert(%Post{topics: []}) do
    :ok
  end

  def handle_insert(%Post{topics: topics}) do
    # Do work required to inform subscribed users.
  end

  # Defined for the sake of example. Ignore me!
  def handle_update(old_post, new_post) do
    :ok
  end
end
```

Now that we are starting to use "observable" behaviour, we must modify the way
in which we insert posts with our repo.

```elixir
def create_post(params \\ %{}) do
  %Post{}
  |> Post.changeset(params)
  |> Repo.insert_and_notify()
end
```

Our users will now be informed of any new posts with topics they are interested in!
