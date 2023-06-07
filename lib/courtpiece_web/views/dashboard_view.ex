defmodule CourtPieceWeb.DashboardView do
  use CourtPieceWeb, :view
  alias CourtPiece.Utils.ApiHelper, as: Helper

  def render("dashboards.json", %{game: data}) do
    Helper.response(
      "Data fetched successfully",
      render_many(data, CourtPieceWeb.DashboardView, "dashboard.json", as: :game),
      201
    )
  end

  def render("dashboard.json", %{game: data}) do
    %{
      id: data.id,
      name: data.name,
      title: data.title
    }
  end
end
