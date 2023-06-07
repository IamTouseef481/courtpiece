defmodule CourtPiece.SupportTicketsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CourtPiece.SupportTickets` context.
  """

  @doc """
  Generate a support_ticket.
  """
  def support_ticket_fixture(attrs \\ %{}) do
    {:ok, support_ticket} =
      attrs
      |> Enum.into(%{
        category: :suggestion,
        closed_at: ~U[2023-04-03 11:09:00Z],
        department: "some department",
        description: "some description",
        email: "some email",
        name: "some name",
        opened_at: ~U[2023-04-03 11:09:00Z],
        priority: :medium,
        status: :opened
      })
      |> CourtPiece.SupportTickets.create_support_ticket()

    support_ticket
  end
end
