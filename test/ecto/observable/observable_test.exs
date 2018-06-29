defmodule Ecto.ObservableTest do
  use Ecto.Observable.TestCase

  alias Ecto.Observable.{TestRepo, Post, TestObserverOne, TestObserverTwo, TestObserverThree}

  setup do
    TestRepo.delete_observers()

    :ok
  end

  describe "init_observers/1" do
    test "will setup observers on repo init if defined" do
      TestRepo.stop(TestRepo)
      :timer.sleep(100)

      assert {:ok, post} = TestRepo.insert_and_notify(%Post{})
      assert_receive({TestObserverThree, :insert, ^post})
    end
  end

  describe "insert_and_notify/2" do
    test "will insert a struct" do
      assert {:ok, %Post{id: id}} = TestRepo.insert_and_notify(%Post{})
      assert %Post{} = TestRepo.get(Post, id)
    end

    test "will notify a single module observer" do
      TestRepo.add_observer(TestObserverOne, Post, :insert)

      assert {:ok, post} = TestRepo.insert_and_notify(%Post{})
      assert_receive({TestObserverOne, :insert, ^post})
    end

    test "will notify a single function observer" do
      TestRepo.add_observer(insert_function(), Post, :insert)

      assert {:ok, post} = TestRepo.insert_and_notify(%Post{})
      assert_receive({:insert, ^post})
    end

    test "will notify multiple observers" do
      TestRepo.add_observer(TestObserverOne, Post, :insert)
      TestRepo.add_observer(TestObserverTwo, Post, :insert)
      TestRepo.add_observer(insert_function(), Post, :insert)

      assert {:ok, post} = TestRepo.insert_and_notify(%Post{})
      assert_receive({TestObserverOne, :insert, ^post})
      assert_receive({TestObserverTwo, :insert, ^post})
      assert_receive({:insert, ^post})
    end
  end

  describe "insert_and_notify!/2" do
    test "will insert a struct" do
      assert %Post{id: id} = TestRepo.insert_and_notify!(%Post{})
      assert %Post{} = TestRepo.get(Post, id)
    end

    test "will notify a single module observer" do
      TestRepo.add_observer(TestObserverOne, Post, :insert)

      assert %Post{} = post = TestRepo.insert_and_notify!(%Post{})
      assert_receive({TestObserverOne, :insert, ^post})
    end

    test "will notify a single function observer" do
      TestRepo.add_observer(insert_function(), Post, :insert)

      assert %Post{} = post = TestRepo.insert_and_notify!(%Post{})
      assert_receive({:insert, ^post})
    end

    test "will notify multiple observers" do
      TestRepo.add_observer(TestObserverOne, Post, :insert)
      TestRepo.add_observer(TestObserverTwo, Post, :insert)
      TestRepo.add_observer(insert_function(), Post, :insert)

      assert %Post{} = post = TestRepo.insert_and_notify!(%Post{})
      assert_receive({TestObserverOne, :insert, ^post})
      assert_receive({TestObserverTwo, :insert, ^post})
      assert_receive({:insert, ^post})
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

    test "will notify a single module observer" do
      TestRepo.add_observer(TestObserverOne, Post, :update)
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert {:ok, new_post} = TestRepo.update_and_notify(change)
      assert_receive({TestObserverOne, :update, ^post, ^new_post})
    end

    test "will notify a single function observer" do
      TestRepo.add_observer(update_function(), Post, :update)
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert {:ok, new_post} = TestRepo.update_and_notify(change)
      assert_receive({:update, ^post, ^new_post})
    end

    test "will notify multiple observers" do
      TestRepo.add_observer(TestObserverOne, Post, :update)
      TestRepo.add_observer(TestObserverTwo, Post, :update)
      TestRepo.add_observer(update_function(), Post, :update)
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert {:ok, new_post} = TestRepo.update_and_notify(change)
      assert_receive({TestObserverOne, :update, ^post, ^new_post})
      assert_receive({TestObserverTwo, :update, ^post, ^new_post})
      assert_receive({:update, ^post, ^new_post})
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

    test "will notify a single module observer" do
      TestRepo.add_observer(TestObserverOne, Post, :update)
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert %Post{} = new_post = TestRepo.update_and_notify!(change)
      assert_receive({TestObserverOne, :update, ^post, ^new_post})
    end

    test "will notify a single function observer" do
      TestRepo.add_observer(update_function(), Post, :update)
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert %Post{} = new_post = TestRepo.update_and_notify!(change)
      assert_receive({:update, ^post, ^new_post})
    end

    test "will notify multiple observers" do
      TestRepo.add_observer(TestObserverOne, Post, :update)
      TestRepo.add_observer(TestObserverTwo, Post, :update)
      TestRepo.add_observer(update_function(), Post, :update)
      {:ok, post} = TestRepo.insert(%Post{})
      change = Ecto.Changeset.change(post, %{title: "foo"})

      assert %Post{} = new_post = TestRepo.update_and_notify!(change)
      assert_receive({TestObserverOne, :update, ^post, ^new_post})
      assert_receive({TestObserverTwo, :update, ^post, ^new_post})
      assert_receive({:update, ^post, ^new_post})
    end
  end

  describe "delete_and_notify/2" do
    test "will delete a struct" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, %Post{id: id}} = TestRepo.delete_and_notify(post)
      assert TestRepo.get(Post, id) == nil
    end

    test "will notify a single module observer" do
      TestRepo.add_observer(TestObserverOne, Post, :delete)
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, post} = TestRepo.delete_and_notify(post)
      assert_receive({TestObserverOne, :delete, ^post})
    end

    test "will notify a single function observer" do
      TestRepo.add_observer(delete_function(), Post, :delete)
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, post} = TestRepo.delete_and_notify(post)
      assert_receive({:delete, ^post})
    end

    test "will notify multiple observers" do
      TestRepo.add_observer(TestObserverOne, Post, :delete)
      TestRepo.add_observer(TestObserverTwo, Post, :delete)
      TestRepo.add_observer(delete_function(), Post, :delete)
      {:ok, post} = TestRepo.insert(%Post{})

      assert {:ok, post} = TestRepo.delete_and_notify(post)
      assert_receive({TestObserverOne, :delete, ^post})
      assert_receive({TestObserverTwo, :delete, ^post})
      assert_receive({:delete, ^post})
    end
  end

  describe "delete_and_notify!/2" do
    test "will insert a struct" do
      {:ok, post} = TestRepo.insert(%Post{})

      assert %Post{id: id} = TestRepo.delete_and_notify!(post)
      assert TestRepo.get(Post, id) == nil
    end

    test "will notify a single module observer" do
      TestRepo.add_observer(TestObserverOne, Post, :delete)
      {:ok, post} = TestRepo.insert(%Post{})

      assert %Post{} = post = TestRepo.delete_and_notify!(post)
      assert_receive({TestObserverOne, :delete, ^post})
    end

    test "will notify a single function observer" do
      TestRepo.add_observer(delete_function(), Post, :delete)
      {:ok, post} = TestRepo.insert(%Post{})

      assert %Post{} = post = TestRepo.delete_and_notify!(post)
      assert_receive({:delete, ^post})
    end

    test "will notify multiple observers" do
      TestRepo.add_observer(TestObserverOne, Post, :delete)
      TestRepo.add_observer(TestObserverTwo, Post, :delete)
      TestRepo.add_observer(delete_function(), Post, :delete)
      {:ok, post} = TestRepo.insert(%Post{})

      assert %Post{} = post = TestRepo.delete_and_notify!(post)
      assert_receive({TestObserverOne, :delete, ^post})
      assert_receive({TestObserverTwo, :delete, ^post})
      assert_receive({:delete, ^post})
    end
  end

  describe "add_observer/1" do
    test "will add all observations defined by the observer" do
      assert TestRepo.add_observer(TestObserverThree) == [true]
      assert [TestObserverThree] = TestRepo.get_observers(Post, :insert)
    end
  end

  describe "add_observer/3" do
    test "will add a single observer" do
      assert TestRepo.add_observer(TestObserverOne, Post, :insert) == true
      assert [TestObserverOne] = TestRepo.get_observers(Post, :insert)
    end
  end

  describe "add_observers/" do
    test "will add a multiple observers" do
      observers = [
        {TestObserverOne, Post, :insert},
        {TestObserverTwo, Post, :update},
        TestObserverThree
      ]

      assert TestRepo.add_observers(observers) == [true, true, [true]]

      assert [insert: [TestObserverThree, TestObserverOne], update: [TestObserverTwo], delete: []] =
               TestRepo.get_observers(Post)
    end
  end

  describe "get_observers/1" do
    test "will get all observers for a schema" do
      observers = [{TestObserverOne, Post, :insert}, {TestObserverTwo, Post, :update}]
      TestRepo.add_observers(observers)

      assert [insert: [TestObserverOne], update: [TestObserverTwo], delete: []] =
               TestRepo.get_observers(Post)
    end
  end

  describe "get_observers/2" do
    test "will get all observers for a schema action" do
      observers = [{TestObserverOne, Post, :insert}, {TestObserverTwo, Post, :insert}]
      TestRepo.add_observers(observers)

      assert [TestObserverTwo, TestObserverOne] = TestRepo.get_observers(Post, :insert)
    end
  end

  def insert_function do
    fn action, [struct] -> send(self(), {action, struct}) end
  end

  def update_function do
    fn action, [old_struct, new_struct] -> send(self(), {action, old_struct, new_struct}) end
  end

  def delete_function do
    insert_function()
  end
end
