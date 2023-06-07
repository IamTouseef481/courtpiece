defmodule CourtPieceWeb.SessionFallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(CourtPieceWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(403)
    |> put_view(CourtPieceWeb.ErrorView)
    |> render(:"403")
  end

  def call(conn, {:error, reason}) when reason in [:invalid_o_auth, :invalid_grant] do
    conn
    |> put_status(401)
    |> put_view(CourtPieceWeb.ErrorView)
    |> render(:"401")
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> assign(:error, message)
    |> put_status(500)
    |> put_view(CourtPieceWeb.ErrorView)
    |> render(:"501")
  end

  def call(conn, _) do
    conn
    |> put_status(500)
    |> put_view(CourtPieceWeb.ErrorView)
    |> render(:"500")
  end
end
