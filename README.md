# Ecto Observable

[![Build Status](https://travis-ci.org/nsweeting/ecto_observable.svg?branch=master)](https://travis-ci.org/nsweeting/ecto_observable)
[![Ecto.Observable Version](https://img.shields.io/hexpm/v/ecto_observable.svg)](https://hex.pm/packages/ecto_observable)

Ecto Observable adds "observable" functionality to `Ecto.Repo`.

## Installation

The package can be installed by adding `ecto_observable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_observable, "~> 0.2.0"}
  ]
end
```
## Documentation

See [HexDocs](https://hexdocs.pm/ecto_observable) for additional documentation.

## Getting Started

Lets say we have a `Post` schema. Each post can have many topics. Users can
subscribe to a given topic. Whenever a post is created for a given topic, we
are responsible for informing the subscribed users.

Given the above, lets setup our new "observable" repo.

```elixir
defmodule Repo do
  use Ecto.Repo, otp_app: :my_app
  use Observable.Repo
end
```

We have defined our repo as normal - but with the addition of `use Observable.Repo`
to bring in the required observable functionality.

Lets create our new observer now.

```elixir
defmodule SubscribersObserver do
  use Observable, :observer

  # Lets ignore posts that dont have any topics.
  def handle_notify({:insert, %Post{topics: []}}) do
    :ok
  end

  # Lets ignore posts that dont have any topics.
  def handle_notify({:insert, %Post{topics: topics}}) do
    # Do work required to inform subscribed users.
  end

  # Defined for the sake of example. Ignore me!
  def handle_notify({:update, [old_post, new_post]}) do
    :ok
  end
end
```

Now that we have our observer set up, lets modify our Post schema to support
notifying our observers.

```elixir

defmodule Post do
  use Ecto.Schema
  use Observable, :observer

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:topics, {:array, :string}, default: [])
  end

  observations do
    on_action(:insert, SubscribersObserver)
    on_action(:update, SubscribersObserver)
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
