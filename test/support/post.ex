defmodule Observable.Post do
  use Ecto.Schema
  use Observable, :notifier

  schema "posts" do
    field(:title, :string)
  end

  observations do
    on_action(:insert, Observable.TestObserverOne)
    on_action(:insert, Observable.TestObserverTwo)
    on_action(:update, Observable.TestObserverOne)
    on_action(:update, Observable.TestObserverTwo)
    on_action(:delete, Observable.TestObserverOne)
    on_action(:delete, Observable.TestObserverTwo)
  end
end
