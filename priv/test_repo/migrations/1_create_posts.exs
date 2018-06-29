defmodule Ecto.Observable.TestRepo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
    end
  end
end
