defmodule Observable.PostRaise do
  use Ecto.Schema
  use Observable, :notifier

  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
  end

  observations do
    action(:insert, [Observable.TestObserverThree])
    action(:update, [Observable.TestObserverThree])
    action(:delete, [Observable.TestObserverThree])
  end

  @doc false
  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:title])
    |> validate_required([:title])
  end
end
