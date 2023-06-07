defmodule CourtPiece.FriendsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CourtPiece.Friends` context.
  """

  @doc """
  Generate a friend.
  """
  def friend_fixture(attrs \\ %{}) do
    {:ok, friend} =
      attrs
      |> Enum.into(%{
        status: :accepted,
        request_from: attrs[:request_from]
      })
      |> CourtPiece.Friends.create_friend()

    friend
  end
end
