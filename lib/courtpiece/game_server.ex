defmodule CourtPiece.GameServer do
  @moduledoc """
  A GameServer for managing state for a specific game instance.
  """
  alias CourtPiece.GameAgent
  alias CourtPiece.GameServer
  alias CourtPiece.GamesSupervisor
  alias CourtPiece.GameState
  alias CourtPiece.Schemas.GameStateHelper, as: GSH
  alias CourtPieceWeb.Helper.GameHelper
  alias CourtPieceWeb.Utils.Deck

  use GenServer

  def child_spec(opts) do
    name = Keyword.get(opts, :name, GameServer)
    init_params = Keyword.get(opts, :init_params)

    %{
      id: "#{GameServer}_#{name}",
      start: {GameServer, :start_link, [name, init_params]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  #  #####################################
  #  ########   Public Functions  ########
  #  #####################################

  @doc """
  Start a GameServer with the given game_code as the name.
  """
  def start_link(game_code, %{} = init_params) do
    case GenServer.start_link(__MODULE__, %{init_params: init_params}, name: global_tuple(game_code)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  @doc """
  This function searches for running game against the type and either joins the matching game or starts a new instance
  """
  def start_game(game_type, bet_value, player_id) do
    with {:ok, game_code} <- GameAgent.fetch_pending_games(game_type),
         {:ok, pid} <- find_game(game_code),
         :joined <- join_game(pid, player_id, bet_value),
         :ok <- maybe_full_action(pid) do
      {:ok, %{"gameCode" => game_code}}
    else
      :not_found ->
        generate_game_code()
        |> then(fn code ->
          init_params = %{code: code, type: game_type, initial_players: [{player_id, "waiting"}], bet_value: bet_value}
          new_game(init_params)
          {:ok, %{"gameCode" => code}}
        end)

      {:game_full, game_code} ->
        {:ok, pid} = find_game(game_code)
        :ok = maybe_full_action(pid)

        generate_game_code()
        |> then(fn code ->
          init_params = %{code: code, type: game_type, initial_players: [{player_id, "waiting"}], bet_value: bet_value}
          new_game(init_params)
        end)

        {:ok, %{"gameCode" => game_code}}

      :joined ->
        :joined
    end
  end

  @doc """
  This function distributes cards and generate hand cards for players
  """
  def distribute_initial_cards(game_code) do
    with {:ok, pid} <- find_game(game_code),
         :ok <- select_initiator_and_turn_wise_players(pid),
         {:ok, state} <- distribute_cards(pid, 5) do
      Task.start(fn ->
        GameHelper.create_teams(state)
      end)

      {:ok, state}
    else
      :not_found ->
        :not_found
    end
  end

  @doc """
  This function sets and broadcasts trump suit
  distributes cards and generate hand cards for players after trump suit selection
  broadcast his/her all hand cards to player
  broadcasts next_turn
  """
  def set_trump_suit(game_code, trump_suit) do
    with {:ok, pid} <- find_game(game_code),
         {:ok, _} <- trump_suit(pid, trump_suit),
         {:ok, state} <- distribute_cards(pid, 4) do
      GameState.broadcast(Deck.suits(), game_code, state.initiator)

      Task.start(fn ->
        GameHelper.create_hands(state)
      end)

      {:ok, state}
    else
      :not_found -> :not_found
      error -> error
    end
  end

  @doc """
  Updates state of game on every trick and closes server on last trick after deciding winner
  """
  def played_trick(game_code, player_id, card) do
    with {:ok, pid} <- find_game(game_code),
         {:ok, state} <- update_turn(pid, player_id, card),
         :ok <- close_server_if_game_finished(pid, state.status) do
      Task.start(fn ->
        GameHelper.update_hands(Map.merge(state, %{player_id: player_id}))
      end)

      {:ok, state}
    else
      :not_found -> :not_found
      error -> error
    end
  end

  #  #####################################
  #  ######## Genserver callbacks ########
  #  #####################################

  @impl true
  def init(%{init_params: %{code: _code, initial_players: [_player_touple], type: _type} = init_params} = _stack) do
    {:ok, GameState.new(init_params)}
  end

  def update_game_status(game_code, new_status) do
    {:ok, pid} = game_code |> find_game()

    GenServer.call(pid, {:update_status, new_status})
  end

  def update_initial_players(game_code, new_players_list) do
    {:ok, pid} = game_code |> find_game()

    GenServer.call(pid, {:update_initial_players, new_players_list})
  end

  @impl true
  def handle_call({:join_game, player_id, bet_value}, _x, state) do
    case GameState.join_game(state, player_id, bet_value) do
      {:ok, new_state} ->
        {:reply, :joined, new_state}

      {:error, "Game is full"} ->
        {:reply, {:game_full, state.game_code}, state}
    end
  end

  @impl true
  def handle_call({:update_status, new_status}, _, state) do
    new_state = GameState.update_status(state, new_status)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:update_initial_players, new_players_list}, _, state) do
    new_state = GameState.update_initial_players(state, new_players_list)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_state, _, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call(:select_initiator, _, state) do
    with {:ok, new_state} <- GameState.select_initiator(state),
         :ok <- broadcast_initiator(new_state) do
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:distribute_cards, card_count}, _, state) do
    {:ok, new_state} = GameState.distribute_cards(state, card_count)
    {:ok, new_state} = GameState.create_teams(new_state)
    {:reply, {:ok, new_state}, new_state}
  end

  @impl true
  def handle_call({:trump_suit, trump_suit}, _, state) do
    with {:ok, new_state} <- GameState.trump_suit(state, trump_suit),
         data <- %{trumpsuit: new_state.trump_suit},
         :ok <- CourtPieceWeb.Endpoint.broadcast("game:" <> state.code, "trump_suit", data) do
      {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call({:update_turn, %{player_id: player_id, card: card}}, _, state) do
    with true <- player_id == state.next_turn,
         %{"suit" => _, "rank" => _} <- card,
         {:ok, _} <- GSH.valid_played_card(card, state.player_hands[player_id], state.current_turn_cards),
         last_player? <- GSH.last_player?(player_id, state.turnwise_players),
         {:ok, new_state} <- GameState.update_turn(state, player_id, card, last_player?) do
      if last_player?,
        do:
          Task.start(fn ->
            GameHelper.create_completed_turns(%{
              code: state.code,
              senior: new_state.senior,
              completed_turns: new_state.completed_turns,
              current_turn_cards: state.current_turn_cards,
              player_id: player_id,
              card: card
            })
          end)

      {:reply, {:ok, new_state}, new_state}
    else
      false ->
        error = "Its not your turn"
        error_broadcast(state.code, error, player_id)
        {:reply, {:error, "Its not your turn"}, state}

      {:error, error} ->
        error_broadcast(state.code, error, player_id)
        {:reply, {:error, error}, state}

      _ ->
        error = "Something wrong in parameters"
        error_broadcast(state.code, error, player_id)
    end
  end

  #  #####################################
  #  ########  Helper functions   ########
  #  #####################################

  defp new_game(%{code: game_code, type: game_type, initial_players: _player_id_list} = init_params) do
    GameAgent.add_new_pending_game(game_code, game_type)

    Supervisor.start_child(GamesSupervisor, {CourtPiece.GameServer, name: game_code, init_params: init_params})
  end

  defp join_game(pid, player_id, bet_value) do
    GenServer.call(pid, {:join_game, player_id, bet_value})
  end

  @doc """
  Given a Genserver pid, it invokes the :get_state callback
  """
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def close_server_if_game_finished(pid, :finished), do: GenServer.stop(pid)

  def close_server_if_game_finished(_, _), do: :ok

  def error_broadcast(game_code, error, player_id) do
    CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "error", %{"error" => error, "player_id" => player_id})
  end

  defp global_tuple(game_code) do
    {:global, game_code}
  end

  @spec find_game(String.t()) :: :not_found | {:ok, pid()}
  defp find_game(game_code) do
    case GenServer.whereis(global_tuple(game_code)) do
      nil -> :not_found
      pid -> {:ok, pid}
    end
  end

  @spec generate_game_code() :: String.t()
  defp generate_game_code do
    Enum.reduce_while(1..100, "", fn _x, _acc ->
      game_code = GameState.game_code()

      game_code
      |> find_game()
      |> then(fn
        :not_found -> {:halt, game_code}
        _ -> {:cont, ""}
      end)
    end)
  end

  @spec maybe_full_action(pid()) :: :ok
  defp maybe_full_action(pid) do
    {:ok, state} = get_state(pid)

    case length(state.initial_players) do
      4 ->
        GameAgent.remove_pending_game(state.code, state.type)
        :ok

      _ ->
        :ok
    end
  end

  @spec select_initiator_and_turn_wise_players(pid()) :: :ok
  defp select_initiator_and_turn_wise_players(pid) do
    GenServer.call(pid, :select_initiator)
  end

  @spec distribute_cards(pid(), integer()) :: {:ok, struct()}
  defp distribute_cards(pid, card_count) do
    GenServer.call(pid, {:distribute_cards, card_count})
  end

  @spec trump_suit(pid(), String.t()) :: {:ok, struct()}
  defp trump_suit(pid, trump_suit) do
    GenServer.call(pid, {:trump_suit, trump_suit})
  end

  @spec update_turn(pid(), binary, map) :: {:ok, struct()}
  defp update_turn(pid, player_id, card) do
    GenServer.call(pid, {:update_turn, %{player_id: player_id, card: card}})
  end

  @spec broadcast_initiator(struct()) :: :ok
  defp broadcast_initiator(%{code: game_code, initiator: initiator}) do
    CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "card_distributor", %{card_distributor: initiator})
    :ok
  end

  @spec game_started?(String.t()) :: boolean
  def game_started?(game_code) do
    with {:ok, pid} <- find_game(game_code),
         {:ok, %GameState{status: :ready}} <- get_state(pid) do
      # We are calling create_runing_game sync way because, there is another process after it
      # with async call runs the first and this process runs after it.
      GameHelper.create_runing_game(%{game_code: game_code, status: "ready"})
      true
    else
      _ -> false
    end
  end

  @spec get_game_state(String.t()) :: {:ok, struct()} | :not_found
  def get_game_state(game_code) do
    with {:ok, pid} <- find_game(game_code),
         {:ok, %GameState{}} = state <- get_state(pid) do
      state
    end
  end

  def leave_game(game_code, user_id) do
    {:ok, state} = get_game_state(game_code)

    if length(state.initial_players) == 4 do
      {:error, ["Game has started. You cannot leave the game"]}
    else
      new_players_list = state.initial_players -- [{user_id, "joined"}]
      update_initial_players(game_code, new_players_list)
      user = CourtPiece.Accounts.get_user_for_broadcasting_on_game_table(user_id)
      CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "game_left", user)
      {:ok, ["You Left"]}
    end
  end
end
