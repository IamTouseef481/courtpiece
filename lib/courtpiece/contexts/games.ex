defmodule CourtPiece.Games do
  @moduledoc """
  The Games context.
  """

  alias CourtPiece.Games.Game
  import Ecto.Query, warn: false

  alias CourtPiece.Games.GameTable
  alias CourtPiece.Repo

  defp query do
    from(g in Game,
      where: is_nil(g.deleted_at)
    )
  end

  def get_game_id_by(type) do
    Game
    |> where([g], g.name == ^type)
    |> limit(1)
    |> Repo.one()
  end

  def get_game_table_by(game_id) do
    GameTable
    |> where([gt], gt.game_id == ^game_id)
    |> select([gt], gt.bet_value)
    |> Repo.all()
  end

  def get_all_games do
    query()
    |> Repo.all()
  end

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end
end
