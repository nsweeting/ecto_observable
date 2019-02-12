defmodule Observable.PostError do
  use Ecto.Schema
  use Observable, :notifier

  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
  end

  observations do
    action(:insert, [Observable.TestObserverFour])
    action(:update, [Observable.TestObserverFour])
    action(:delete, [Observable.TestObserverFour])
  end

  @doc false
  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:title])
    |> validate_required([:title])
  end
end
