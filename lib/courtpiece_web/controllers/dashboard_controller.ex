defmodule CourtPieceWeb.DashboardController do
  use CourtPieceWeb, :controller

  alias CourtPiece.Games
  use PhoenixSwagger

  swagger_path :get_game_types do
    get("/games")
    produces("application/json")
    security([%{Bearer: []}])
    description("Get all game Types")
    response(200, "Ok", Schema.ref(:ListGamesTypes))
  end

  def get_game_types(conn, _params) do
    games = Games.get_all_games()

    conn
    |> put_status(201)
    |> render("dashboards.json", %{game: games})
  end

  def swagger_definitions do
    %{
      ListGamesTypes:
        swagger_schema do
          title("List Of Dynamic Filters")
          description("List Of Dynamic Filters")
        end
    }
  end
end
