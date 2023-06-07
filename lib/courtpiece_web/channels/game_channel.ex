defmodule CourtPieceWeb.GameChannel do
  @moduledoc """
    GameChannel
  """
  use Phoenix.Channel
  alias CourtPiece.Accounts
  alias CourtPiece.Contexts.Statistics
  alias CourtPiece.GameServer

  def join("game:" <> game_code, _message, socket) do
    send(self(), :after_join)

    {:ok, assign(socket, :game_code, game_code)}
  end

  def handle_info(:after_join, %{assigns: %{user_id: user_id}} = socket) do
    game_code = socket.assigns.game_code
    {:ok, %{initial_players: initial_players}} = CourtPiece.GameServer.get_game_state(game_code)
    users = make_user_object_for_boradcast(initial_players)
    CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "joined_users", users)

    updated_player_ids =
      Enum.map(initial_players, fn
        {^user_id, "waiting"} -> {user_id, "joined"}
        players -> players
      end)

    GameServer.update_initial_players(game_code, updated_player_ids)

    if game_joined_by_all?(updated_player_ids) do
      GameServer.update_game_status(game_code, :ready)

      CourtPieceWeb.Endpoint.broadcast("game:" <> game_code, "game_started", users)
      # 5 cards for each player
      GameServer.distribute_initial_cards(game_code)
    end

    {:noreply, socket}
  end

  def make_user_object_for_boradcast(initial_players) do
    initial_players
    |> Enum.map(fn {player_id, _} ->
      Accounts.get_user_for_broadcasting_on_game_table(player_id)
    end)
  end

  @doc """
  trump_suit -> When dealer selects trump suit, this event is triggered.
  play_trick -> When player played his/her trick, this event is triggered.
  """

  def handle_in("trump_suit", %{"trump_suit" => trump_suit}, socket) do
    GameServer.set_trump_suit(socket.assigns.game_code, trump_suit)
    {:noreply, socket}
  end

  def handle_in("user_profile", %{"user_id" => user_id}, socket) do
    stats = Statistics.get_player_stats(%{user_id: user_id})

    {:reply, {:ok, stats}, socket}
  end

  def handle_in("play_trick", %{"card" => card}, socket) do
    GameServer.played_trick(socket.assigns.game_code, socket.assigns.user_id, card)
    {:noreply, socket}
  end

  def handle_in("leave_game", %{}, socket) do
    case GameServer.leave_game(socket.assigns.game_code, socket.assigns.user_id) do
      {:error, msg} -> {:reply, {:error, %{message: msg}}, socket}
      {:ok, msg} -> {:reply, {:ok, %{message: msg}}, socket}
    end
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  intercept ["cards_in_hand", "error", "updated_player_hands", "playable_suits"]

  def handle_out("cards_in_hand", payloads, socket) do
    Enum.each(payloads["hand"], fn {player_id, hand} ->
      if socket.assigns.user_id == player_id do
        push(socket, "cards_in_hand", Map.merge(payloads, %{"hand" => hand}))
      end
    end)

    {:noreply, socket}
  end

  def handle_out("updated_player_hands", %{"player_id" => player_id} = payloads, socket) do
    if socket.assigns.user_id == player_id do
      push(socket, "updated_player_hands", payloads)
    end

    {:noreply, socket}
  end

  def handle_out("error", %{"player_id" => player_id} = payloads, socket) do
    if socket.assigns.user_id == player_id do
      push(socket, "error", payloads)
    end

    {:noreply, socket}
  end

  def handle_out("playable_suits", %{"player_id" => player_id, "playable_suits" => playable_suits}, socket) do
    if socket.assigns.user_id == player_id do
      push(socket, "playable_suits", %{"playable_suits" => playable_suits})
    end

    {:noreply, socket}
  end

  defp game_joined_by_all?(player_ids_list) when length(player_ids_list) == 4 do
    Enum.all?(player_ids_list, fn
      {_id, "waiting"} -> false
      {_id, "joined"} -> true
    end)
  end

  defp game_joined_by_all?(_player_ids_list), do: false
end
