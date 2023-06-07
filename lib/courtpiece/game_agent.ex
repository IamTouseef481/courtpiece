defmodule CourtPiece.GameAgent do
  @moduledoc """
  A GameAgent for managing state for how many pending game instances there.
  """

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{"single" => [], "double" => [], "ace" => [], "hidden" => []} end, name: __MODULE__)
  end

  def add_new_pending_game(game_code, game_type) do
    Agent.update(__MODULE__, &Map.put(&1, game_type, &1[game_type] ++ [game_code]))
  end

  def remove_pending_game(game_code, game_type) do
    Agent.update(__MODULE__, &Map.put(&1, game_type, List.delete(&1[game_type], game_code)))
  end

  def fetch_pending_games(game_type) do
    games = Agent.get(__MODULE__, & &1)

    games[game_type]
    |> then(fn
      [code | _] -> {:ok, code}
      _ -> :not_found
    end)
  end

  def fetch_all_pending_games do
    Agent.get(__MODULE__, & &1)
  end
end
