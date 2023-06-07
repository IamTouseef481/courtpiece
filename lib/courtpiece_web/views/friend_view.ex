defmodule CourtPieceWeb.FriendView do
  use CourtPieceWeb, :view
  alias CourtPiece.Utils.ApiHelper, as: Helper
  #    alias __MODULE__

  def render("search_users.json", %{user_data: data}) do
    Helper.response(
      "Users fetched successfully",
      render_many(data, CourtPieceWeb.SessionView, "user_short_object.json", as: :user_data),
      200
    )
  end

  def render("friend_requests.json", %{data: data}) do
    Helper.response(
      "Friend Request",
      data,
      200
    )
  end

  def render("friends.json", %{data: data}) do
    Helper.response(
      "Friends fetched successfully",
      render_many(data, CourtPieceWeb.SessionView, "user_short_object.json", as: :user_data),
      200
    )
  end

  def render("update_friend_request.json", %{data: data}) do
    Helper.response(
      "Actions on Friend Request",
      data,
      200
    )
  end

  def render("delete_friend.json", %{deleted_friend: _friend}) do
    Helper.response(
      "Friend deleted successfully.",
      %{},
      200
    )
  end

  def render("user.json", %{error: error}) do
    %{errors: %{status_code: 400, message: error}}
  end

  def render("fb_friends.json", %{data: data}),
    do:
      Helper.response(
        "Facebook Friend List.",
        data,
        200
      )
end
