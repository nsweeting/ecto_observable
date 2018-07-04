defmodule Observable.Post do
  use Ecto.Schema
  use Observable, :notifier

  schema "posts" do
    field(:title, :string)
  end

  observations do
    action(:insert, [Observable.TestObserverOne, Observable.TestObserverTwo])
    action(:update, [Observable.TestObserverOne, Observable.TestObserverTwo])
    action(:delete, [Observable.TestObserverOne, Observable.TestObserverTwo])
  end
end
