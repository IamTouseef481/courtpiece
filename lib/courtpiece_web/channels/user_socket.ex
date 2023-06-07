defmodule CourtPieceWeb.UserSocket do
  use Phoenix.Socket

  alias CourtPiece.Accounts

  channel "user:*", CourtPieceWeb.UserChannel
  channel "game:*", CourtPieceWeb.GameChannel

  def connect(%{"device_id" => device_id, "AUTHORIZATION" => token}, socket, _headers) do
    with {:ok, %{device_id: device_id_, user_id: id}} <- CourtPiece.Token.verify(token),
         true <- device_id == device_id_,
         user when not is_nil(user) <- Accounts.get_user(id, device_id) do
      {:ok, assign(socket, :user_id, user.id)}
    else
      _x ->
        {:error, socket}
    end
  end

  def id(socket), do: "users_socket:#{socket.assigns.user_id}"

  #  CourtPieceWeb.Endpoint.broadcast("users_socket:" <> user.id, "disconnect", %{})
end
