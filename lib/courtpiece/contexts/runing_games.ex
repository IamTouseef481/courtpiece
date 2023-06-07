defmodule CourtPiece.RuningGames do
  @moduledoc """
  The Runing Games context.
  """

  import Ecto.Query, warn: false

  alias CourtPiece.Games.{RuningGame, RuningGameHistory}
  alias CourtPiece.Hands.{CompletedTurn, CompletedTurnHistory, Hand, HandHistory}
  alias CourtPiece.Repo
  alias CourtPiece.Teams.{Team, TeamHistory}

  def create_runing_game(attrs \\ %{}) do
    %RuningGame{}
    |> RuningGame.changeset(attrs)
    |> Repo.insert()
  end

  def update_runing_game(%RuningGame{} = runing_game, attrs) do
    runing_game
    |> RuningGame.changeset(attrs)
    |> Repo.update()
  end

  def get_runing_game_by(game_code) do
    from(rg in RuningGame,
      where: rg.game_code == ^game_code
    )
    |> Repo.one()
  end

  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  def create_team_history(attrs \\ []) do
    Repo.insert_all(TeamHistory, attrs)
  end

  def create_hand_history(attrs \\ []) do
    Repo.insert_all(HandHistory, attrs)
  end

  def create_completed_turns_history(attrs \\ []) do
    Repo.insert_all(CompletedTurnHistory, attrs)
  end

  def get_hand_by(player_id, runing_game_id) do
    from(h in Hand,
      where: h.player_id == ^player_id and h.runing_game_id == ^runing_game_id
    )
    |> Repo.one()
  end

  def create_hand(attrs \\ %{}) do
    %Hand{}
    |> Hand.changeset(attrs)
    |> Repo.insert()
  end

  def update_hand(%Hand{} = hand, attrs) do
    hand
    |> Hand.changeset(attrs)
    |> Repo.update()
  end

  def create_completed_turns(attrs \\ %{}) do
    %CompletedTurn{}
    |> CompletedTurn.changeset(attrs)
    |> Repo.insert()
  end

  def create_runing_games_history(attrs) do
    attrs = Map.from_struct(attrs)

    %RuningGameHistory{}
    |> RuningGameHistory.changeset(attrs)
    |> Repo.insert()
  end

  def delete_runing_games(runing_game) do
    Repo.delete(runing_game)
  end

  def query(module, runing_game_id) do
    module
    |> where([h], h.runing_game_id == ^runing_game_id)
  end

  def delete_all(module, runing_game_id) do
    query(module, runing_game_id)
    |> Repo.delete_all()
  end

  def get_by(module, runing_game_id) do
    query(module, runing_game_id)
    |> Repo.all()
  end
end
