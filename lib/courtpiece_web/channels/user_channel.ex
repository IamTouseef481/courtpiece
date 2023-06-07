defmodule CourtPieceWeb.UserChannel do
  @moduledoc """
    UserChannel
  """
  use Phoenix.Channel

  alias CourtPiece.Contexts.Statistics
  alias CourtPiece.Games
  alias CourtPiece.Notifications
  alias CourtPieceWeb.Helper.GameHelper
  # alias CourtPieceWeb.Presence

  def join("user:" <> _user_id, _message, socket) do
    # check if GameServer is running, if yes, retrieve state.
    # if no: keep record in presence for lobby

    send(self(), :after_join)

    {:ok, socket}
  end

  @spec handle_info(:after_join, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_info(:after_join, socket) do
    # push(socket, "presence_state", Presence.list(socket))
    # user_id = socket.assigns.user_id

    # {:ok, _} =
    #   Presence.track(socket, "#{user_id}", %{
    #     user_id: user_id
    #   })
    count = Notifications.get_unread_notifications_count(socket.assigns.user_id)
    push(socket, "unread_notifications_count", %{"unread_notifications_count" => count})

    {:noreply, socket}
  end

  def handle_in("user_profile", %{"user_id" => user_id}, socket) do
    stats = Statistics.get_player_stats(%{user_id: user_id})

    {:reply, {:ok, stats}, socket}
  end

  def handle_in("start_game", %{"game_type" => type, "bet_value" => bet_value}, socket) do
    case CourtPiece.GameServer.start_game(type, bet_value, socket.assigns.user_id) do
      {:ok, %{"gameCode" => _}} = reply -> {:reply, reply, socket}
      _ -> {:noreply, socket}
    end
  end

  def handle_in("game_invitation", %{"body" => _body}, socket) do
    {:noreply, socket}
  end

  def handle_in("game_table", %{"game_id" => game_id}, socket) do
    {:reply, {:ok, Games.get_game_table_by(game_id)}, socket}
  end

  def handle_in("update_profile", payloads, socket) do
    case GameHelper.update_profile_and_user(payloads, socket.assigns.user_id) do
      {:ok, msg} -> {:reply, {:ok, %{message: msg}}, socket}
      {:error, msg} -> {:reply, {:error, %{message: msg}}, socket}
    end
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # intercept ["presence_state", "presence_diff"]

  # def handle_out("presence_state", _params, socket) do
  #   {:noreply, socket}
  # end

  # def handle_out("presence_diff", _params, socket) do
  #   {:noreply, socket}
  # end
end
