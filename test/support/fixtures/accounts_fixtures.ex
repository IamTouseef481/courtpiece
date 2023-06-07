defmodule CourtPiece.AccountsFixtures do
  import CourtPiece.Factory

  @moduledoc """
  This module defines test helpers for creating
  entities via the `CourtPiece.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    insert(:user, attrs)
  end

  @doc """
  Generate a session.
  """
  def session_fixture(attrs \\ %{}) do
    insert(:session, attrs)
  end

  @doc """
  Generate a social_auth.
  """
  def social_auth_fixture(attrs \\ %{}) do
    insert(:social_auth, attrs)
  end
end
