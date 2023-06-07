defmodule CourtPieceWeb.NotificationController do
  use CourtPieceWeb, :controller
  action_fallback(CourtPieceWeb.SessionFallbackController)
  alias CourtPiece.Notifications
  alias CourtPieceWeb.CommonParameters

  use PhoenixSwagger

  swagger_path :index do
    get("/notifications")
    produces("application/json")
    security([%{Bearer: []}])
    description("Fetch List of Notifications")

    parameters do
      page(:query, :string, "Page")
      page_size(:query, :string, "Page Size")
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def index(conn, params) do
    data = Notifications.paginate_notifications(conn.assigns.current_user.id, params["page"], params["page_size"])

    conn
    |> put_status(200)
    |> render("notifications.json", %{notifications: data})
  end

  def swagger_definitions do
    %{
      Notifications:
        swagger_schema do
          title("Notification record by id")
          description("Notification record by id")

          CommonParameters.authorization_props()
        end
    }
  end
end
