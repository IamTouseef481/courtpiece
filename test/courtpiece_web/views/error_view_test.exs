defmodule CourtPieceWeb.ErrorViewTest do
  use CourtPieceWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(CourtPieceWeb.ErrorView, "404.json", []) == %{error: %{detail: "Not Found"}}
  end

  test "renders 500.json" do
    assert render(CourtPieceWeb.ErrorView, "500.json", []) ==
             %{error: %{detail: "Internal Server Error"}}
  end
end
