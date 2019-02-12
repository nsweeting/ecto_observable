defmodule Observable.RepoTest do
  use Observable.TestCase

  alias Ecto.Multi
  alias Observable.{TestRepo, Post, PostRaise, TestObserverOne, TestObserverTwo}

  describe "insert_and_notify/2" do
    test "will insert a struct" do
      assert {:ok, %Post{id: id}} = TestRepo.insert_and_notify(%Post{})
      assert %Post{} = TestRepo.get(Post, id)
    end

    test "will notify observers" do
      old = %Post{}
      assert {:ok, new} = TestRepo.insert_and_notify(old)
      assert_receive({TestObserverOne, :insert, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :insert, TestRepo, ^old, ^new})
    end

    test "will notify observers within a transaction" do
      old = %Post{}

      new =
        TestRepo.transaction(fn ->
          TestRepo.insert_and_notify(old)
        end)
        |> case do
          {:ok, {:ok, new}} -> new
        end

      assert_receive({TestObserverOne, :insert, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :insert, TestRepo, ^old, ^new})
    end

    test "will notify observers within a multi" do
      old = %Post{}

      new =
        Multi.new()
        |> Multi.run(:test, fn _, _ -> TestRepo.insert_and_notify(old) end)
        |> TestRepo.transaction()
        |> case do
          {:ok, %{test: new}} -> new
        end

      assert_receive({TestObserverOne, :insert, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :insert, TestRepo, ^old, ^new})
    end

    test "will not notify observers if the changeset is invalid" do
      old = %Post{}
      changeset = Post.changeset(old, %{})

      refute changeset.valid?
      assert {:error, _changeset} = TestRepo.insert_and_notify(changeset)
      refute_receive({TestObserverOne, :insert, TestRepo, _old, _new})
      refute_receive({TestObserverTwo, :insert, TestRepo, _old, _new})
    end

    test "will not insert a record if an observer raises an error" do
      assert TestRepo.aggregate(PostRaise, :count, :id) == 0

      assert_raise(RuntimeError, fn ->
        TestRepo.insert_and_notify(%PostRaise{})
      end)

      assert TestRepo.aggregate(PostRaise, :count, :id) == 0
    end
  end

  describe "update_and_notify/2" do
    test "will update a struct" do
      assert {:ok, post} = TestRepo.insert(%Post{})
      assert %Post{title: nil} = TestRepo.get(Post, post.id)

      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert {:ok, %Post{title: "foo"}} = TestRepo.update_and_notify(change)
      assert %Post{title: "foo"} = TestRepo.get(Post, post.id)
    end

    test "will notify observers" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Ecto.Changeset.change(old, %{title: "foo"})

      assert {:ok, new} = TestRepo.update_and_notify(changeset)
      assert_receive({TestObserverOne, :update, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :update, TestRepo, ^old, ^new})
    end

    test "will notify observers within a transaction" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Ecto.Changeset.change(old, %{title: "foo"})

      new =
        TestRepo.transaction(fn ->
          TestRepo.update_and_notify(changeset)
        end)
        |> case do
          {:ok, {:ok, new}} -> new
        end

      assert_receive({TestObserverOne, :update, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :update, TestRepo, ^old, ^new})
    end

    test "will notify observers within a multi" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Ecto.Changeset.change(old, %{title: "foo"})

      new =
        Multi.new()
        |> Multi.run(:test, fn _, _ -> TestRepo.update_and_notify(changeset) end)
        |> TestRepo.transaction()
        |> case do
          {:ok, %{test: new}} -> new
        end

      assert_receive({TestObserverOne, :update, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :update, TestRepo, ^old, ^new})
    end

    test "will not notify observers if the changeset is invalid" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Post.changeset(old)

      refute changeset.valid?
      assert {:error, _changeset} = TestRepo.update_and_notify(changeset)
      refute_receive({TestObserverOne, :update, TestRepo, _old, _new})
      refute_receive({TestObserverTwo, :update, TestRepo, _old, _new})
    end

    test "will not update a record if an observer raises an error" do
      {:ok, old} = TestRepo.insert(%PostRaise{})
      changeset = Ecto.Changeset.change(old, %{title: "foo"})

      assert_raise(RuntimeError, fn ->
        TestRepo.update_and_notify(changeset)
      end)

      assert %{title: nil} = TestRepo.get!(PostRaise, old.id)
    end
  end

  describe "delete_and_notify/2" do
    test "will delete a struct" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, %Post{id: id}} = TestRepo.delete_and_notify(post)
      assert TestRepo.get(Post, id) == nil
    end

    test "will notify observers" do
      {:ok, old} = TestRepo.insert(%Post{})

      assert {:ok, new} = TestRepo.delete_and_notify(old)
      assert_receive({TestObserverOne, :delete, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :delete, TestRepo, ^old, ^new})
    end

    test "will notify observers within a transaction" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Ecto.Changeset.change(old, %{title: "foo"})

      new =
        TestRepo.transaction(fn ->
          TestRepo.delete_and_notify(changeset)
        end)
        |> case do
          {:ok, {:ok, new}} -> new
        end

      assert_receive({TestObserverOne, :delete, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :delete, TestRepo, ^old, ^new})
    end

    test "will notify observers within a multi" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Ecto.Changeset.change(old, %{title: "foo"})

      new =
        Multi.new()
        |> Multi.run(:test, fn _, _ -> TestRepo.delete_and_notify(changeset) end)
        |> TestRepo.transaction()
        |> case do
          {:ok, %{test: new}} -> new
        end

      assert_receive({TestObserverOne, :delete, TestRepo, ^old, ^new})
      assert_receive({TestObserverTwo, :delete, TestRepo, ^old, ^new})
    end

    test "will not notify observers if the changeset is invalid" do
      {:ok, old} = TestRepo.insert(%Post{})
      changeset = Post.changeset(old)

      refute changeset.valid?
      assert {:error, _changeset} = TestRepo.delete_and_notify(changeset)
      refute_receive({TestObserverOne, :delete, TestRepo, _old, _new})
      refute_receive({TestObserverTwo, :delete, TestRepo, _old, _new})
    end

    test "will not delete a record if an observer raises an error" do
      {:ok, old} = TestRepo.insert(%PostRaise{})

      assert TestRepo.aggregate(PostRaise, :count, :id) == 1

      assert_raise(RuntimeError, fn ->
        TestRepo.delete_and_notify(old)
      end)

      assert TestRepo.aggregate(PostRaise, :count, :id) == 1
    end
  end
end
