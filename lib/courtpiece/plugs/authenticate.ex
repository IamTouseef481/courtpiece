defmodule CourtPiece.Plug.Authenticate do
  import Plug.Conn
  require Logger
  @moduledoc false
  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, data} <- CourtPiece.Token.verify(token) do
      conn
      |> assign(:current_user, CourtPiece.Accounts.get_user!(data.user_id))
    else
      _error ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(CourtPieceWeb.ErrorView)
        |> Phoenix.Controller.render(:"401")
        |> halt()
    end
  end
end
