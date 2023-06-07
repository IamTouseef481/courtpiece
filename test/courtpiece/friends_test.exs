defmodule CourtPiece.FriendsTest do
  use CourtPiece.DataCase

  alias CourtPiece.Factory
  alias CourtPiece.Friends
  alias CourtPiece.Friends.Friend
  import CourtPiece.FriendsFixtures
  import CourtPiece.AccountsFixtures

  @invalid_attrs %{status: nil}
  setup do
    user_params = Factory.user_factory(user_role: "social") |> Map.from_struct()
    user_params1 = Factory.user_factory(user_role: "guest") |> Map.from_struct()
    user1 = user_fixture(user_params)
    user2 = user_fixture(user_params1)

    {:ok, user1: user1, user2: user2}
  end

  describe "test friends" do
    test "list_friends/0 returns all friends", context do
      user1 = context[:user1]
      user2 = context[:user2]
      friend = friend_fixture(%{request_from_id: user1.id, request_to_id: user2.id})
      assert Friends.list_friends() == [friend]
    end

    test "get_friend!/1 returns the friend with given id", context do
      user1 = context[:user1]
      user2 = context[:user2]
      friend = friend_fixture(%{request_from_id: user1.id, request_to_id: user2.id})
      assert Friends.get_friend!(friend.id) == friend
    end

    test "create_friend/1 with valid data creates a friend", context do
      user1 = context[:user1]
      user2 = context[:user2]
      valid_attrs = %{request_from_id: user1.id, request_to_id: user2.id, status: :accepted}

      assert {:ok, %Friend{} = friend} = Friends.create_friend(valid_attrs)
      assert friend.status == :accepted
    end

    test "create_friend/1 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} = Friends.create_friend(@invalid_attrs)
    end

    test "update_friend/2 with valid data updates the friend", context do
      user1 = context[:user1]
      user2 = context[:user2]
      friend = friend_fixture(%{request_from_id: user1.id, request_to_id: user2.id})
      update_attrs = %{status: :accepted}

      assert {:ok, %Friend{} = friend} = Friends.update_friend(friend, update_attrs)
      assert friend.status == :accepted
    end

    test "update_friend/2 with invalid data returns error changeset", context do
      user1 = context[:user1]
      user2 = context[:user2]
      friend = friend_fixture(%{request_from_id: user1.id, request_to_id: user2.id})
      assert {:error, %Ecto.Changeset{}} = Friends.update_friend(friend, @invalid_attrs)
      assert friend == Friends.get_friend!(friend.id)
    end

    test "delete_friend/1 deletes the friend", context do
      user1 = context[:user1]
      user2 = context[:user2]
      friend = friend_fixture(%{request_from_id: user1.id, request_to_id: user2.id})
      assert {:ok, %Friend{}} = Friends.delete_friend(friend)
      assert_raise Ecto.NoResultsError, fn -> Friends.get_friend!(friend.id) end
    end

    test "change_friend/1 returns a friend changeset", context do
      user1 = context[:user1]
      user2 = context[:user2]
      friend = friend_fixture(%{request_from_id: user1.id, request_to_id: user2.id})
      assert %Ecto.Changeset{} = Friends.change_friend(friend)
    end
  end
end
