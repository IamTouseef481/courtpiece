defmodule CourtPiece.Schemas.GameStateHelper do
  @moduledoc """
  Helper module for dealing GameState struct
  """
  alias CourtPiece.GameState

  @doc """
  Takes list of ranks and returns sorted list of strings
  """
  @spec sorting_cards(list) :: list
  def sorting_cards(data) do
    data
    |> Enum.map(&to_string/1)
    |> Enum.sort_by(
      fn
        "jack" -> 11
        "queen" -> 12
        "king" -> 13
        "ace" -> 14
        # Should be handled at point of origin
        x -> String.to_integer(x)
      end,
      :desc
    )
  end

  @doc """
  Checks this player is last in tricks round or not
  """

  @spec last_player?(binary, list) :: boolean
  def last_player?(player_id, turnwise_players) do
    if List.last(turnwise_players) == player_id, do: true, else: false
  end

  @doc """
  Checks weather this played card suit is valid according initial played suite or not
  """

  @spec valid_played_card(map, map, list) :: {:ok, any} | {:error, String.t()}
  def valid_played_card(%{"suit" => suit, "rank" => rank}, player_hand, []) do
    player_ranks = player_hand[suit |> String.to_atom()] || []
    played_card_in_hand(rank, player_ranks)
  end

  def valid_played_card(%{"suit" => suit, "rank" => rank}, player_hand, [{_, %{"suit" => initial_suit}} | _]) do
    player_ranks = player_hand[suit |> String.to_atom()] || []
    initial_ranks = player_hand[initial_suit |> String.to_atom()] || []

    if initial_ranks == [] do
      played_card_in_hand(rank, player_ranks)
    else
      played_card_in_hand(suit, initial_suit, rank, player_ranks)
    end
  end

  @doc """
  Checks weather this played card exists in that player's hand or not
  """

  @spec played_card_in_hand(any, any, any, any) :: {:error, <<_::192, _::_*48>>} | {:ok, <<_::40>>}
  def played_card_in_hand(suit, initial_suit, rank, player_ranks) do
    if suit == initial_suit do
      played_card_in_hand(rank, player_ranks)
    else
      {:error, "You can't play this suit"}
    end
  end

  def played_card_in_hand(rank, player_ranks),
    do: if(rank in player_ranks, do: {:ok, "valid"}, else: {:error, "Player does not have this card"})

  @doc """
  If last trick of round:
  1. Decides senior
  2. Update turn wise players list
  3. Updates total completed turns count
  4. Update Pending Score(cards/4) which is not won by any team yet
  4. Update Score of that team(cards/4) which won that pending score
  On each trick:
  1. Updates next turn player
  2. Updates remaining player hand cards after played his/her trick
  3. Updates current turn cards that are currently on table
  """

  def update_state_on_trick(
        %GameState{
          trump_suit: trump_suit,
          current_turn_cards: current_turn_cards,
          turnwise_players: prev_turnwise_players,
          player_hands: player_hands,
          pending_score: pending_score,
          completed_turns: completed_turns,
          team_score: team_score,
          teams: teams,
          senior: prev_senior
        } = state,
        player_id,
        card,
        last_player?
      ) do
    current_senior = decide_senior(current_turn_cards ++ [{player_id, card}], trump_suit, prev_senior)
    turnwise_players = update_turnwise_players(last_player?, current_senior, prev_turnwise_players)
    completed_turns = if last_player?, do: completed_turns + 1, else: completed_turns

    Map.merge(
      state,
      %{
        turnwise_players: turnwise_players,
        next_turn: find_next_turn(player_id, turnwise_players, prev_turnwise_players),
        player_hands: update_player_hand(player_id, card, player_hands),
        current_turn_cards: update_current_turn_cards(last_player?, player_id, card, current_turn_cards),
        senior: current_senior,
        pending_score: update_pending_score(last_player?, prev_senior, pending_score, current_senior, completed_turns),
        completed_turns: completed_turns,
        team_score:
          compute_team_score(
            last_player?,
            prev_senior,
            team_score,
            teams,
            pending_score,
            current_senior,
            completed_turns
          )
      }
    )
  end

  @doc """
  Update turn wise players on last trick
  """

  @spec update_turnwise_players(boolean, binary, list) :: list | {:error, String.t()}
  def update_turnwise_players(true, senior, players), do: turnwise_players(players, senior)

  def update_turnwise_players(false, _, players), do: players

  @spec turnwise_players(list, binary) :: list
  def turnwise_players(players, initiator) do
    index = Enum.find_index(players, &(&1 == initiator))

    if index == 0, do: players, else: Enum.slice(players, index..3) ++ Enum.slice(players, 0..(index - 1))
  end

  @spec find_next_turn(binary, list, list) :: binary
  def find_next_turn(player_id, turnwise_players, prev_turnwise_players) do
    index = Enum.find_index(prev_turnwise_players, &(&1 == player_id))
    next_index = if index == 3, do: 0, else: index + 1
    Enum.at(turnwise_players, next_index)
  end

  @spec update_player_hand(binary, map, map) :: map
  def update_player_hand(player_id, %{"suit" => suit, "rank" => rank}, player_hands) do
    suit = suit |> String.to_atom()
    ranks = player_hands[player_id][suit]
    ranks = ranks && List.delete(ranks, rank)
    {_, updated_hands} = get_and_update_in(player_hands[player_id][suit], &{&1, ranks})
    updated_hands
  end

  @spec update_current_turn_cards(boolean, binary, map, list) :: list
  def update_current_turn_cards(true, _, _, _), do: []

  def update_current_turn_cards(false, player_id, card, cards), do: cards ++ [{player_id, card}]

  @spec update_pending_score(boolean, binary, integer, binary | nil, integer) :: integer
  def update_pending_score(true, _, _, _, 13), do: 0

  def update_pending_score(true, prev_senior, previous_score, current_senior, completed_turns) do
    if current_senior == prev_senior && previous_score > 0 && completed_turns >= 3 do
      0
    else
      previous_score + 1
    end
  end

  def update_pending_score(false, _, previous_score, _, _), do: previous_score

  @spec compute_team_score(boolean, binary, integer, map, integer, binary | nil, integer) :: integer
  def compute_team_score(true, _, previous_score, teams, pending_score, current_senior, 13) do
    update_team_score(current_senior, teams, previous_score, pending_score)
  end

  def compute_team_score(true, prev_senior, previous_score, teams, pending_score, current_senior, completed_turns) do
    if current_senior == prev_senior && pending_score > 0 && completed_turns >= 3 do
      update_team_score(current_senior, teams, previous_score, pending_score)
    else
      previous_score
    end
  end

  def compute_team_score(false, _, previous_score, _, _, _, _), do: previous_score

  @spec update_team_score(binary, map, map, integer) :: map
  def update_team_score(current_senior, teams, previous_score, pending_score) do
    if current_senior in teams.a do
      # + 1 for current turn seniority
      Map.put(previous_score, :a, previous_score.a + pending_score + 1)
    else
      Map.put(previous_score, :b, previous_score.b + pending_score + 1)
    end
  end

  @spec decide_senior(list, String.t(), binary) :: binary
  def decide_senior(current_turn_cards, trump_suit, _) when length(current_turn_cards) == 4 do
    [{_, %{"suit" => initial_suit}} = initial_turn | remaining_cards] = current_turn_cards

    {senior_player, _} =
      Enum.reduce(remaining_cards, initial_turn, fn
        {_, %{"suit" => current_suit, "rank" => current_rank}} = turn,
        {_, %{"suit" => senior_suit, "rank" => senior_rank}} = senior ->
          cond do
            current_suit == senior_suit ->
              find_senior_from_two_same_suit_players([current_rank, senior_rank], senior, turn)

            current_suit == trump_suit and initial_suit != trump_suit ->
              turn

            current_suit != trump_suit and senior_suit == trump_suit ->
              senior

            current_suit != initial_suit ->
              senior

            true ->
              senior
          end
      end)

    senior_player
  end

  def decide_senior(_, _, prev_senior), do: prev_senior

  @doc """
  Takes list of ranks and returns sorted list of strings
  """
  @spec find_senior_from_two_same_suit_players(list, tuple, tuple) :: map
  def find_senior_from_two_same_suit_players([current_rank, senior_rank], senior, current) do
    if rank_mapping(current_rank) > rank_mapping(senior_rank), do: current, else: senior
  end

  def rank_mapping(rank) do
    case rank do
      "jack" -> 11
      "queen" -> 12
      "king" -> 13
      "ace" -> 14
      x when is_binary(x) -> String.to_integer(x)
      x -> x
    end
  end

  # @doc """
  # Alternate way to find senior
  # """

  # @spec decide_senior2(list, String.t()) :: binary
  # def decide_senior2(current_turn_cards, trump_suit) do
  #   {player_ids, cards} = Enum.unzip(current_turn_cards)
  #   [_initial_suit | suits] = Enum.map(cards, & &1["suit"])

  #   cond do
  #     Enum.uniq(suits) |> length() == 1 ->
  #       find_senior_rank_from_same_suits(player_ids, cards)
  #       # should be sorted as rank
  #       current_turn_cards

  #     trump_suit in suits ->
  #       # trumps should be ranked and other sas 0
  #       current_turn_cards

  #     trump_suit not in suits ->
  #       # rank initial suit and others of that initial suit and other suits as 0
  #       current_turn_cards
  #   end
  # end

  # @doc """
  # Takes list of ranks and returns sorted list of strings
  # """
  # @spec find_senior_rank_from_same_suits(list, list) :: binary
  # def find_senior_rank_from_same_suits(player_ids, cards) do
  #   ranks = cards |> Enum.map(& &1["rank"])

  #   senior_rank =
  #     ranks
  #     |> Enum.sort_by(
  #       fn
  #         "jack" -> 11
  #         "queen" -> 12
  #         "king" -> 13
  #         "ace" -> 14
  #         # Should be handled at point of origin
  #         x -> String.to_integer(x)
  #       end,
  #       :desc
  #     )
  #     |> List.first()

  #   senior_index = Enum.find_index(ranks, &(&1 == senior_rank))
  #   Enum.at(player_ids, senior_index)
  # end
end
