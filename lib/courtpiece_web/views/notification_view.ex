defmodule CourtPieceWeb.NotificationView do
  use CourtPieceWeb, :view
  alias CourtPiece.Utils.ApiHelper, as: Helper
  #    alias __MODULE__

  def render("notifications.json", %{notifications: data}) do
    page_data = %{
      total_rows: data.total_entries,
      page: data.page_number,
      total_pages: data.total_pages
    }

    data = %{
      pagination: page_data,
      notifications: render_many(data.entries, CourtPieceWeb.NotificationView, "notification.json"),
      unread_notifications_count: data.unread_notifications_count
    }

    Helper.response(
      "Notifications fetched successfully",
      data,
      200
    )
  end

  def render("show.json", %{notification: notification}) do
    Helper.response(
      "Notification fetched successfully",
      render_one(notification, CourtPieceWeb.NotificationView, "notification.json"),
      200
    )
  end

  def render("update.json", %{notification: notification}) do
    Helper.response(
      "Notification updated successfully",
      render_one(notification, CourtPieceWeb.NotificationView, "notification.json"),
      200
    )
  end

  def render("error.json", %{error: error}) do
    Helper.response(
      "Something went wrong",
      %{error: error},
      204
    )
  end

  def render("notification.json", %{notification: notification}) do
    notification
  end
end
