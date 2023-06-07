defmodule CourtPiece.GameState do
  @moduledoc """
  A schema for maintaining state of a game instance
  """
  alias __MODULE__
  alias CourtPiece.Contexts.Statistics
  alias CourtPiece.Schemas.GameStateHelper, as: GSH
  alias CourtPieceWeb.Helper.GameHelper
  alias CourtPieceWeb.Utils.Deck

  defstruct code: nil,
            # :not_started, :ready, :finished
            status: :not_started,
            type: "",
            # [{user_id, ("waiting" || "joined")}]
            initial_players: [],
            turnwise_players: [],
            player_hands: %{},
            teams: %{a: [], b: []},
            deck: [],
            initiator: "",
            trump_suit: "",
            next_turn: "",
            current_turn_cards: [],
            senior: "",
            completed_turns: 0,
            pending_score: 0,
            team_score: %{a: 0, b: 0},
            bet_value: %{}

  def new(%{code: _code, initial_players: [{player_id, _state}], type: _type} = init_state) do
    Map.merge(
      %GameState{},
      init_state |> Map.merge(%{deck: Deck.shuffle(), bet_value: %{"#{player_id}" => init_state.bet_value}})
    )
  end

  @doc """
  Adds the player in the game, only 4 players are allowed.
  """
  def join_game(%GameState{initial_players: players, bet_value: prev_bet_value} = game_state, player_id, bet_value)
      when length(players) < 4 do
    case Enum.find(players, &(elem(&1, 0) == player_id)) do
      nil ->
        new_player = {player_id, "waiting"}

        state =
          game_state
          |> update_state(:initial_players, [new_player | players])
          |> update_state(:bet_value, Map.put(prev_bet_value, player_id, bet_value))

        # |> update_status()

        {:ok, state}

      _x ->
        {:ok, game_state}
    end
  end

  def join_game(_game_state, _player, _bet_value) do
    {:error, "Game is full"}
  end

  @doc """
  distribute 5 cards to each player if card_count is 5 and add these distributed cards to hands in state
  remove these distributed card from deck in state

  distribute 4 cards to each player twice if card_count is 4 and add these distributed cards to hands in state
  remove these distributed card from deck in state
  """
  def distribute_cards(%GameState{turnwise_players: players} = game_state, card_count) do
    players =
      case card_count do
        4 -> players ++ players
        2 -> players ++ players ++ players ++ players
        _ -> players
      end

    %{code: code, player_hands: hands} =
      updated_state =
      Enum.reduce(players, game_state, fn player_id, game_state ->
        distribute_cards_to_hands(player_id, card_count, game_state)
      end)

    CourtPieceWeb.Endpoint.broadcast("game:" <> code, "cards_in_hand", %{"hand" => hands})
    {:ok, updated_state}
  end

  def create_teams(%GameState{initial_players: [{p1, _}, {p2, _}, {p3, _}, {p4, _}]} = game_state) do
    {:ok, Map.merge(game_state, %{teams: %{a: [p1, p3], b: [p2, p4]}})}
  end

  @doc """
  This function adds selected trump suit to state
  """
  def trump_suit(%GameState{} = game_state, trump_suit) do
    updated_state =
      game_state
      |> update_state(:trump_suit, trump_suit)

    {:ok, updated_state}
  end

  @doc """
  This function
  1. updates state
  2. Fetches playable suites for each player regarding first played suit to disable other suit cards
  3. Broadcast tricks required data on game table against following events
  i) current_turn_cards -> Cards on table
  ii) updated_player_hands -> updated cards of that player
  iii) next_turn -> next turn player and which suits he/she can play
  iV) after_completed_trick -> senior, pending_score and team score
  """
  def update_turn(
        %GameState{next_turn: next_turn} = game_state,
        player_id,
        %{"suit" => _, "rank" => _} = card,
        last_player?
      )
      when next_turn == player_id do
    updated_state = GSH.update_state_on_trick(game_state, player_id, card, last_player?)
    updated_state = game_win(last_player?, updated_state)
    broadcast_next_turn(updated_state)
    broadcast_current_turn_cards(updated_state.code, game_state.current_turn_cards, card)
    broadcast_updated_player_hands(player_id, updated_state)
    broadcast_after_completed_trick(last_player?, updated_state)

    {:ok, updated_state}
  end

  def broadcast_current_turn_cards(game_code, current_turn_cards, card) do
    make_current_turn_cards_for_broadcast = Enum.map(current_turn_cards, &(&1 |> elem(1))) ++ [card]

    CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "current_turn_cards", %{
      "current_turn_cards" => make_current_turn_cards_for_broadcast
    })
  end

  def broadcast_updated_player_hands(player_id, updated_state) do
    CourtPieceWeb.Endpoint.broadcast("game:" <> updated_state.code, "updated_player_hands", %{
      "player_id" => player_id,
      "player_hands" => updated_state.player_hands[player_id]
    })
  end

  def broadcast_next_turn(%GameState{status: :finished}), do: :game_ended

  def broadcast_next_turn(%GameState{code: game_code, next_turn: next_turn} = state) do
    playable_suits(state)
    |> broadcast(game_code, next_turn)
  end

  def broadcast(playable_suits, game_code, next_turn) do
    CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "next_turn", %{
      "player_id" => next_turn
    })

    CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "playable_suits", %{
      "player_id" => next_turn,
      "playable_suits" => playable_suits
    })
  end

  def broadcast_after_completed_trick(last_player?, _) when last_player? == false, do: true

  def broadcast_after_completed_trick(last_player?, updated_state) when last_player? == true do
    CourtPieceWeb.Endpoint.broadcast("game:" <> updated_state.code, "after_completed_trick", %{
      "team_score" => updated_state.team_score,
      "senior" => updated_state.senior,
      "pending_score" => updated_state.pending_score
    })
  end

  @doc """
  This function decides winning team players
  if one team have score equal or more than 7 and other team does not have any score game continues until court
  if one team have score equal or more than 7 and other team have some score that team wins
  """
  @spec game_win(boolean, struct) :: struct
  def game_win(true, %{team_score: score, teams: teams} = state) do
    cond do
      score.a >= 7 and score.b > 0 -> game_finished_and_broadcast_message(state, teams.a, teams.b)
      score.b >= 7 and score.a > 0 -> game_finished_and_broadcast_message(state, teams.b, teams.a)
      true -> state
    end
  end

  def game_win(false, state), do: state

  defp game_finished_and_broadcast_message(%GameState{} = state, winning_players, loosing_players) do
    CourtPieceWeb.Endpoint.broadcast("game:" <> state.code, "game_won", %{
      "winning_players" => CourtPiece.Accounts.get_user_for_broadcasting_on_game_table(winning_players),
      "loosing_players" => CourtPiece.Accounts.get_user_for_broadcasting_on_game_table(loosing_players)
    })

    Task.start(fn ->
      GameHelper.get_and_update_runing_game(state.code, %{status: :finished})
      GameHelper.update_total_coins_on_game_ends(state, winning_players)
      GameHelper.create_history_and_delete_records(state)
      update_players_stats(winning_players, loosing_players)
    end)

    update_state(state, :status, :finished)
  end

  def update_players_stats(winners, losers) do
    Statistics.update_after_game(winners, :winner)
    Statistics.update_after_game(losers, :loser)
  end

  defp distribute_cards_to_hands(
         player_id,
         card_count,
         %GameState{deck: deck, player_hands: hands, initiator: initiator} = state
       ) do
    {hand, deck} = Enum.split(deck, card_count)

    prev_hand = Map.get(hands, player_id) || %{}

    updated_hand = Map.put(hands, player_id, make_hand(prev_hand, hand))

    state
    |> update_state(:player_hands, updated_hand)
    |> update_state(:deck, deck)
    |> update_state(:next_turn, initiator)
  end

  def make_hand(prev_hand, hand) do
    prev_hand =
      if Map.keys(prev_hand) == [] do
        %{diamonds: [], spades: [], hearts: [], clubs: []}
      else
        prev_hand
      end

    hand = hand |> Enum.group_by(fn {k, _v} -> k end)

    prev_hand
    |> Enum.reduce(%{diamonds: [], spades: [], hearts: [], clubs: []}, fn {k, v}, acc ->
      Map.merge(acc, %{k => (Keyword.values(hand[k] || []) ++ v) |> GSH.sorting_cards()})
    end)
  end

  @doc """
  Select a random player and add turn wise players to state
  """
  def select_initiator(%GameState{initial_players: players} = game_state) when length(players) == 4 do
    # Filtering out players_id
    players = Enum.map(players, fn {player_id, _status} -> player_id end)
    initiator = Enum.random(players)

    updated_state =
      game_state
      |> update_state(:turnwise_players, GSH.turnwise_players(players, initiator))
      |> update_state(:initiator, initiator)

    {:ok, updated_state}
  end

  @doc """
  Generates a random gamecode
  """
  def game_code do
    Enum.random(1..1000) |> then(&"#{&1}_#{&1 * 8}")
  end

  defp update_state(state, key, value) do
    Map.update!(state, key, fn _ -> value end)
  end

  def update_status(%GameState{} = game_state, new_status) do
    %GameState{game_state | :status => new_status}
  end

  def update_initial_players(%GameState{initial_players: _} = game_state, new_players_list) do
    %GameState{game_state | :initial_players => new_players_list}
  end

  @doc """
  This function computes playable suites on each trick
  """

  @spec playable_suits(map) :: list
  def playable_suits(%{next_turn: next_turn, player_hands: hand, current_turn_cards: []}),
    do: Map.keys(hand[next_turn]) |> Enum.map(&to_string(&1))

  def playable_suits(%{
        next_turn: next_turn,
        player_hands: hand,
        current_turn_cards: [{_, %{"suit" => initial_suit}} | _]
      }) do
    if hand[next_turn][initial_suit |> String.to_atom()] in [nil, []] do
      Map.keys(hand[next_turn]) |> Enum.map(&to_string(&1))
    else
      [initial_suit]
    end
  end

  @doc """
  This function checks weather turn is of that player or not
  """

  @spec player_valid_for_trick?(binary, binary) :: boolean
  def player_valid_for_trick?(player_id, next_turn) do
    if next_turn == player_id, do: true, else: false
  end
end
