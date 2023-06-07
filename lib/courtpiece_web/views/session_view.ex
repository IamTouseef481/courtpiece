defmodule CourtPieceWeb.SessionView do
  use CourtPieceWeb, :view
  alias CourtPiece.Utils.ApiHelper, as: Helper
  alias __MODULE__

  def render("new_user.json", %{user_data: data}) do
    Helper.response(
      "User created successfully",
      render_one(data, CourtPieceWeb.SessionView, "user.json", as: :user_data),
      201
    )
  end

  def render("new_guest.json", %{user_data: data}) do
    Helper.response(
      "User created successfully",
      render_one(data, CourtPieceWeb.SessionView, "guest.json", as: :user_data),
      201
    )
  end

  def render("user.json", %{user_data: data}) do
    %{
      user: render("user_short_object.json", user_data: data),
      token: data[:token],
      games: render_many(data[:games] || [], SessionView, "game.json", as: :game)
    }
  end

  def render("guest.json", %{user_data: data}) do
    %{
      user: render("user_short_object.json", user_data: data),
      token: data[:token],
      games: render_many(data[:games] || [], SessionView, "game.json", as: :game)
    }
  end

  def render("game.json", %{game: game}) do
    %{
      name: game.name,
      title: game.title
    }
  end

  def render("user_short_object.json", %{user_data: data}) do
    %{
      id: data[:id],
      name: data[:name],
      email: data[:email],
      level: data[:level],
      total_coins: data[:total_coins],
      image_url: data[:image_url]
    }
  end

  def render("user.json", %{error: error}) do
    %{errors: %{status_code: 400, message: error}}
  end
end
