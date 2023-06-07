defmodule CourtPieceWeb.Helper.GameHelper do
  @moduledoc """
    This module creates handle database functionality
  """
  use CourtPieceWeb, :courtpiece_helper

  alias CourtPiece.{Games, Players}
  alias CourtPiece.Hands.{CompletedTurn, Hand}
  alias CourtPiece.RuningGames
  alias CourtPiece.Teams.Team

  def create_runing_game(params) do
    new()
    |> run(:runing_game, &create_runing_game/2, &abort/3)
    |> transaction(CourtPiece.Repo, params)
  end

  def create_teams(params) do
    new()
    |> run(:runing_game, &get_runing_game/2, &abort/3)
    |> run(:game, &get_game_id_by/2, &abort/3)
    |> run(:team, &create_team/2, &abort/3)
    |> run(:update_runing_game, &update_runing_game/2, &abort/3)
    |> run(:users_total_coins, &get_and_update_total_coins/2, &abort/3)
    |> transaction(CourtPiece.Repo, params)
  end

  def create_hands(params) do
    new()
    |> run(:runing_game, &get_runing_game/2, &abort/3)
    |> run(:update_runing_game, &update_trump_suit_in_runing_game/2, &abort/3)
    |> run(:hand, &create_hand/2, &abort/3)
    |> transaction(CourtPiece.Repo, params)
  end

  def update_hands(params) do
    new()
    |> run(:runing_game, &get_runing_game/2, &abort/3)
    |> run(:hand, &get_hand/2, &abort/3)
    |> run(:update_hand, &update_hands/2, &abort/3)
    |> transaction(CourtPiece.Repo, params)
  end

  def create_completed_turns(params) do
    new()
    |> run(:runing_game, &get_runing_game/2, &abort/3)
    |> run(:completed_turns, &create_completed_turns/2, &abort/3)
    |> run(:game, &update_runing_game/2, &abort/3)
    |> transaction(CourtPiece.Repo, params)
  end

  def create_history_and_delete_records(params) do
    new()
    |> run(:runing_game, &get_runing_game/2, &abort/3)
    |> run(:runing_game_history, &create_runing_game_history/2, &abort/3)
    |> run(:teams, &get_teams/2, &abort/3)
    |> run(:teams_history, &create_teams_history/2, &abort/3)
    |> run(:hands, &get_hands/2, &abort/3)
    |> run(:hands_history, &create_hands_history/2, &abort/3)
    |> run(:completed_turns, &get_completed_turns/2, &abort/3)
    |> run(:completed_turns_history, &create_completed_turns_history/2, &abort/3)
    |> run(:delete_teams, &delete_teams/2, &abort/3)
    |> run(:delete_completed_turns, &delete_completed_turns/2, &abort/3)
    |> run(:delete_hands, &delete_hands/2, &abort/3)
    |> run(:delete_runing_game, &delete_runing_game/2, &abort/3)
    |> transaction(CourtPiece.Repo, params)
  end

  def create_runing_game(_, params) do
    case RuningGames.create_runing_game(%{
           visibility: "public",
           game_code: params.game_code,
           status: params.status
         }) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["unable to create runing game"]}
    end
  end

  def get_runing_game(_, %{code: game_code}) do
    case RuningGames.get_runing_game_by(game_code) do
      nil -> {:error, ["No runing game found"]}
      runing_game -> {:ok, runing_game}
    end
  end

  def get_game_id_by(_, %{type: type}) do
    case Games.get_game_id_by(type) do
      nil -> {:error, ["No game found"]}
      game -> {:ok, game}
    end
  end

  def get_and_update_total_coins(_, %{bet_value: bet_value}) do
    Enum.each(bet_value, fn {player_id, bet_value} ->
      case Players.get_by(player_id) do
        nil ->
          :do_nothing

        %{total_coins: total_coins} = profile ->
          Players.update_profile(profile, %{total_coins: total_coins - bet_value})
      end
    end)

    {:ok, :get_and_update_total_coins}
  end

  def create_team(%{runing_game: %{id: runing_game_id}, game: %{id: game_id}}, %{bet_value: bet_value} = params) do
    [
      %{
        team_number: "A",
        player_id: params.teams.a |> List.first(),
        game_id: game_id,
        runing_game_id: runing_game_id,
        bet_value: bet_value[params.teams.a |> List.first()]
      },
      %{
        team_number: "B",
        player_id: params.teams.b |> List.first(),
        game_id: game_id,
        runing_game_id: runing_game_id,
        bet_value: bet_value[params.teams.b |> List.first()]
      },
      %{
        team_number: "A",
        player_id: params.teams.a |> List.last(),
        game_id: game_id,
        runing_game_id: runing_game_id,
        bet_value: bet_value[params.teams.a |> List.last()]
      },
      %{
        team_number: "B",
        player_id: params.teams.b |> List.last(),
        game_id: game_id,
        runing_game_id: runing_game_id,
        bet_value: bet_value[params.teams.b |> List.last()]
      }
    ]
    |> Enum.each(fn team ->
      RuningGames.create_team(team)
    end)

    {:ok, :created}
  end

  def update_runing_game(%{runing_game: runing_game}, %{card: _, player_id: _} = params),
    do: update_runing_game(%{runing_game: runing_game, params_to_update: %{current_senior: params.senior}})

  def update_runing_game(%{runing_game: runing_game}, params),
    do: update_runing_game(%{runing_game: runing_game, params_to_update: %{current_senior: params.initiator}})

  def update_runing_game(params) do
    case RuningGames.update_runing_game(params.runing_game, params.params_to_update) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["Unable to update runing game"]}
    end
  end

  def update_trump_suit_in_runing_game(%{runing_game: runing_game}, params) do
    case RuningGames.update_runing_game(runing_game, %{trump_suit: params.trump_suit}) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["Unable to update runing game"]}
    end
  end

  def create_hand(%{runing_game: %{id: runing_game_id}}, %{player_hands: player_hands}) do
    Enum.each(player_hands, fn {player_id, card_in_hand} ->
      RuningGames.create_hand(%{
        player_id: player_id,
        initial_cards: card_in_hand,
        runing_game_id: runing_game_id
      })
    end)

    {:ok, :hands_created}
  end

  def get_hand(%{runing_game: %{id: runing_game_id}}, %{player_id: player_id}) do
    case RuningGames.get_hand_by(player_id, runing_game_id) do
      nil -> {:error, ["no hand found"]}
      data -> {:ok, data}
    end
  end

  def update_hands(%{hand: hand}, %{player_hands: player_hands, player_id: player_id}) do
    cards_to_update = Map.get(player_hands, player_id)

    case RuningGames.update_hand(hand, %{cards: cards_to_update}) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["Unable to update hands"]}
    end
  end

  def create_completed_turns(
        %{runing_game: %{id: id}},
        %{current_turn_cards: current_turn_cards, completed_turns: completed_turns} = params
      ) do
    current_turn_cards =
      current_turn_cards
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        Map.put(acc, k, v)
      end)
      |> Map.put(params.player_id, params.card)

    case RuningGames.create_completed_turns(%{
           turn_number: completed_turns,
           cards: [current_turn_cards],
           runing_game_id: id
         }) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["Unable  to create completed turns"]}
    end
  end

  def update_total_coins_on_game_ends(%{bet_value: bet_value}, winning_players) do
    Enum.each(winning_players, fn player_id ->
      case Players.get_by(player_id) do
        nil ->
          :do_nothing

        %{total_coins: total_coins} = profile ->
          Players.update_profile(profile, %{total_coins: total_coins + bet_value[player_id] * 2})
      end
    end)
  end

  def create_runing_game_history(%{runing_game: runing_game}, _) do
    case RuningGames.create_runing_games_history(runing_game) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["unable to create runing game history"]}
    end
  end

  def get_teams(%{runing_game: %{id: runing_game_id}, runing_game_history: %{id: runing_game_history_id}}, _) do
    case RuningGames.get_by(Team, runing_game_id) do
      nil -> {:error, ["No team found"]}
      teams -> {:ok, struct_to_list_of_maps(teams, runing_game_history_id)}
    end
  end

  def create_teams_history(%{teams: teams}, _) do
    case RuningGames.create_team_history(teams) do
      {_, nil} -> {:ok, [:created]}
      _ -> {:error, ["unable to create teams history"]}
    end
  end

  def get_hands(%{runing_game: %{id: runing_game_id}, runing_game_history: %{id: runing_game_history_id}}, _) do
    case RuningGames.get_by(Hand, runing_game_id) do
      nil -> {:error, ["No hands found"]}
      hands -> {:ok, struct_to_list_of_maps(hands, runing_game_history_id)}
    end
  end

  def create_hands_history(%{hands: hands}, _) do
    case RuningGames.create_hand_history(hands) do
      {_, nil} -> {:ok, [:created]}
      _ -> {:error, ["unable to create teams history"]}
    end
  end

  def get_completed_turns(%{runing_game: %{id: runing_game_id}, runing_game_history: %{id: runing_game_history_id}}, _) do
    case RuningGames.get_by(CompletedTurn, runing_game_id) do
      nil -> {:error, ["No completed turn found"]}
      completed_turns -> {:ok, struct_to_list_of_maps(completed_turns, runing_game_history_id)}
    end
  end

  def create_completed_turns_history(%{completed_turns: completed_turns}, _) do
    case RuningGames.create_completed_turns_history(completed_turns) do
      {_, nil} -> {:ok, [:created]}
      _ -> {:error, ["unable to create completed_turns history"]}
    end
  end

  def delete_teams(%{runing_game: %{id: runing_game_id}}, _), do: {:ok, RuningGames.delete_all(Team, runing_game_id)}
  def delete_hands(%{runing_game: %{id: runing_game_id}}, _), do: {:ok, RuningGames.delete_all(Hand, runing_game_id)}

  def delete_completed_turns(%{runing_game: %{id: runing_game_id}}, _),
    do: {:ok, RuningGames.delete_all(CompletedTurn, runing_game_id)}

  def delete_runing_game(%{runing_game: runing_game}, _), do: RuningGames.delete_runing_games(runing_game)

  def struct_to_list_of_maps(list_of_map, runing_game_history_id) when is_list(list_of_map) do
    Enum.map(list_of_map, fn map_or_struct ->
      if is_struct(map_or_struct) do
        map_or_struct
        |> Map.drop([:__meta__, :__struct__, :game, :runing_game])
        |> Map.merge(%{runing_game_id: runing_game_history_id})
      else
        map_or_struct
        |> Map.drop([:game, :runing_game])
        |> Map.merge(%{runing_game_id: runing_game_history_id})
      end
    end)
  end

  def get_and_update_runing_game(game_code, params) do
    case get_runing_game(params, %{code: game_code}) do
      {:error, error} -> {:error, error}
      {:ok, runing_game} -> update_runing_game(%{runing_game: runing_game, params_to_update: params})
    end
  end

  def update_profile_and_user(payloads, user_id) do
    case Players.get_by(user_id) do
      nil ->
        :do_nothing

      %{user: user} = profile ->
        keys = Map.keys(payloads)
        count = Enum.count(keys)

        cond do
          "name" in keys && count == 1 ->
            update_user(user, %{name: payloads["name"]})

          "name" in keys && count > 1 ->
            update_profile_with_user(profile, payloads)

          true ->
            update_profile(payloads, profile)
        end
    end
  end

  def update_profile_with_user(profile, payloads) do
    with {:ok, _user} <- update_user(profile.user, %{name: payloads["name"]}),
         {:ok, _profile} <- update_profile(payloads, profile) do
      {:ok, ["Update Sucessfully"]}
    else
      {:error, error} -> {:error, error}
    end
  end

  def update_user(user, params) do
    case CourtPiece.Accounts.update_user(user, params) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["Unable to update user"]}
    end
  end

  def update_profile(params, profile) do
    params =
      if Map.get(params, "coins") do
        Map.merge(params, %{"total_coins" => profile.total_coins + params["coins"]})
      else
        params
      end

    case Players.update_profile(profile, params) do
      {:ok, data} -> {:ok, data}
      _ -> {:error, ["Unable to update profile"]}
    end
  end

  def abort(_, _, _), do: :abort
end
