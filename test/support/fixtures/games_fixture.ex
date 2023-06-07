defmodule CourtPiece.GamesFixture do
  import CourtPiece.Factory

  @moduledoc """
  This module defines test helpers for creating
  entities via the `CourtPiece.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    insert(:game, attrs)
  end

  def game_table_fixture(attrs \\ %{}) do
    insert(:game_table, attrs)
  end
end
