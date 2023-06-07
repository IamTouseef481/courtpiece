defmodule CourtPiece.Contexts.Statistics do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias CourtPiece.Repo

  alias CourtPiece.Accounts.User
  alias CourtPiece.Players.Profile
  alias CourtPiece.Schemas.Statistics

  use CourtPiece.Utils.SimpleEctoQueries, ecto_schema: Statistics, ecto_repo: Repo

  @spec create(map()) :: {:ok, Statistics.t()} | {:error, String.t()}
  def create(params) do
    %Statistics{}
    |> Statistics.changeset(params)
    |> Repo.insert()
  end

  @spec update(Statistics.t(), map()) :: {:ok, Statistics.t()} | {:error, String.t()}
  def update(stats, params) do
    changeset = Statistics.changeset(stats, params)
    Repo.update(changeset)
  end

  def get_player_stats(%{user_id: user_id}) do
    from(u in User)
    |> join(:left, [u], p in Profile, on: u.id == p.user_id)
    |> join(:left, [u, p], s in Statistics, on: u.id == s.user_id)
    |> where([u], u.id == ^user_id)
    |> select([u, p, s], %{
      name: u.name,
      coins: p.total_coins,
      image_url: p.image_url,
      level: p.level,
      games_palyed: coalesce(s.games_played, 0),
      games_won: coalesce(s.games_won, 0),
      games_lost: coalesce(s.games_lost, 0),
      last_games: coalesce(s.last_games, [])
    })
    |> Repo.one()
  end

  def create_empty_stats(%{user: user}, _), do: create(%{user_id: user.id})

  def update_after_game(user_ids, result) do
    stats = get_by_user_ids(user_ids)

    Enum.map(stats, fn stat ->
      params = update_params(stat, result)

      {:ok, _stat} =
        Statistics.changeset(stat, params)
        |> Repo.update()
    end)
  end

  def get_by_user_ids(user_ids) do
    from(s in Statistics)
    |> where([s], s.user_id in ^user_ids)
    |> select([s], s)
    |> Repo.all()
  end

  defp update_params(stat, :winner),
    do: %{
      games_played: stat.games_played + 1,
      games_won: stat.games_won + 1,
      last_games: last_five_games(stat.last_games, "W")
    }

  defp update_params(stat, :loser),
    do: %{
      games_played: stat.games_played + 1,
      games_lost: stat.games_lost + 1,
      last_games: last_five_games(stat.last_games, "L")
    }

  defp last_five_games(list, element) do
    if length(list) >= 5 do
      [element | List.delete_at(list, -1)]
    else
      [element | list]
    end
  end
end
