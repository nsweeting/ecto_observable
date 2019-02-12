# Ecto Observable

[![Build Status](https://travis-ci.org/nsweeting/ecto_observable.svg?branch=master)](https://travis-ci.org/nsweeting/ecto_observable)
[![Ecto.Observable Version](https://img.shields.io/hexpm/v/ecto_observable.svg)](https://hex.pm/packages/ecto_observable)

Ecto Observable adds "observable" functionality to `Ecto.Repo`.

## Installation

The package can be installed by adding `ecto_observable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_observable, "~> 0.4"}
  ]
end
```

## Documentation

See [HexDocs](https://hexdocs.pm/ecto_observable) for detailed documentation.

## Example

To get started we must add observability to our repo:

```elixir
defmodule Repo do
  use Ecto.Repo, otp_app: :my_app
  use Observable.Repo
end
```

We can now create an observer:

```elixir
defmodule SubscribersObserver do
  use Observable, :observer

  # Lets ignore posts that dont have any topics.
  def handle_notify(:insert, {_repo, _old, %Post{topics: []}}) do
    :ok
  end

  def handle_notify(:insert, {_repo, _old, %Post{topics: topics}}) do
    # Do work required to inform subscribed users.
  end

  # Defined for the sake of example. Ignore me!
  def handle_notify(:update, {_repo, old, new}) do
    :ok
  end

  # Defined for the sake of example. Ignore me!
  def handle_notify(:delete, {_repo, old, new}) do
    :ok
  end
end
```

And modify our `Post` schema to notify our observer:

```elixir

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
    action(:update, [SubscribersObserver])
    action(:delete, [OtherObserverOne, OtherObserverTwo]) # Defined for the sake of example.
  end
end
```

Which allows us to use the notify functionality:

```elixir
def create_post(params \\ %{}) do
  %Post{}
  |> Post.changeset(params)
  |> Repo.insert_and_notify()
end
```

Please see the [documentation](https://hexdocs.pm/ecto_observable) for more details.