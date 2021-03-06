defmodule Observable.Post do
  use Ecto.Schema
  use Observable, :notifier

  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
  end

  observations do
    action(:insert, [Observable.TestObserverOne, Observable.TestObserverTwo])
    action(:update, [Observable.TestObserverOne, Observable.TestObserverTwo])
    action(:delete, [Observable.TestObserverOne, Observable.TestObserverTwo])
  end

  @doc false
  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:title])
    |> validate_required([:title])
  end
end
