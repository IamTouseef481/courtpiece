defmodule CourtPieceWeb.SupportTicketView do
  use CourtPieceWeb, :view
  alias CourtPiece.Utils.ApiHelper, as: Helper
  #  alias __MODULE__

  def render("tickets.json", %{data: data}) do
    Helper.response(
      "Tickets fetched successfully",
      data,
      200
    )
  end

  def render("created_ticket.json", %{data: _}) do
    Helper.response(
      "Your request for ticket submitted successfully",
      %{},
      200
    )
  end

  def render("updated_ticket.json", %{data: _}) do
    Helper.response(
      "Ticket updated successfully",
      %{},
      200
    )
  end

  def render("ticket.json", %{error: error}) do
    %{errors: %{status_code: 400, message: error}}
  end
end
