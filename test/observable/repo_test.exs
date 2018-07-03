defmodule Observable.RepoTest do
  use Observable.TestCase

  alias Observable.{TestRepo, Post, TestObserverOne, TestObserverTwo}

  describe "insert_and_notify/2" do
    test "will insert a struct" do
      assert {:ok, %Post{id: id}} = TestRepo.insert_and_notify(%Post{})
      assert %Post{} = TestRepo.get(Post, id)
    end

    test "will notify observers" do
      assert {:ok, post} = TestRepo.insert_and_notify(%Post{})
      assert_receive({TestObserverOne, :insert, ^post})
      assert_receive({TestObserverTwo, :insert, ^post})
    end
  end

  describe "insert_and_notify!/2" do
    test "will insert a struct" do
      assert %Post{id: id} = TestRepo.insert_and_notify!(%Post{})
      assert %Post{} = TestRepo.get(Post, id)
    end

    test "will notify observers" do
      assert %Post{} = post = TestRepo.insert_and_notify!(%Post{})
      assert_receive({TestObserverOne, :insert, ^post})
      assert_receive({TestObserverTwo, :insert, ^post})
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
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert {:ok, new_post} = TestRepo.update_and_notify(change)
      assert_receive({TestObserverOne, :update, ^post, ^new_post})
      assert_receive({TestObserverTwo, :update, ^post, ^new_post})
    end
  end

  describe "update_and_notify!/2" do
    test "will update a struct" do
      assert {:ok, post} = TestRepo.insert(%Post{})
      assert %Post{title: nil} = TestRepo.get(Post, post.id)

      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert %Post{title: "foo"} = TestRepo.update_and_notify!(change)
      assert %Post{title: "foo"} = TestRepo.get(Post, post.id)
    end

    test "will notify observers" do
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert %Post{} = new_post = TestRepo.update_and_notify!(change)
      assert_receive({TestObserverOne, :update, ^post, ^new_post})
      assert_receive({TestObserverTwo, :update, ^post, ^new_post})
    end
  end

  describe "delete_and_notify/2" do
    test "will delete a struct" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, %Post{id: id}} = TestRepo.delete_and_notify(post)
      assert TestRepo.get(Post, id) == nil
    end

    test "will notify observers" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, post} = TestRepo.delete_and_notify(post)
      assert_receive({TestObserverOne, :delete, ^post})
      assert_receive({TestObserverTwo, :delete, ^post})
    end
  end

  describe "delete_and_notify!/2" do
    test "will insert a struct" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert %Post{id: id} = TestRepo.delete_and_notify!(post)
      assert TestRepo.get(Post, id) == nil
    end

    test "will notify multiple observers" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert %Post{} = post = TestRepo.delete_and_notify!(post)
      assert_receive({TestObserverOne, :delete, ^post})
      assert_receive({TestObserverTwo, :delete, ^post})
    end
  end
end
