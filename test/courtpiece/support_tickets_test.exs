defmodule CourtPiece.SupportTicketsTest do
  use CourtPiece.DataCase

  alias CourtPiece.SupportTickets

  describe "support_tickets" do
    alias CourtPiece.SupportTickets.SupportTicket

    import CourtPiece.SupportTicketsFixtures

    @invalid_attrs %{
      category: nil,
      closed_at: nil,
      department: nil,
      description: nil,
      email: nil,
      name: nil,
      opened_at: nil,
      priority: nil,
      status: nil
    }

    test "list_support_tickets/0 returns all support_tickets" do
      support_ticket = support_ticket_fixture()
      assert SupportTickets.list_support_tickets() == [support_ticket]
    end

    test "get_support_ticket!/1 returns the support_ticket with given id" do
      support_ticket = support_ticket_fixture()
      assert SupportTickets.get_support_ticket(support_ticket.id) == support_ticket
    end

    test "create_support_ticket/1 with valid data creates a support_ticket" do
      valid_attrs = %{
        category: :suggestion,
        closed_at: ~U[2023-04-03 11:09:00Z],
        department: "some department",
        description: "some description",
        email: "some email",
        name: "some name",
        opened_at: ~U[2023-04-03 11:09:00Z],
        priority: :medium,
        status: :opened
      }

      assert {:ok, %SupportTicket{} = support_ticket} = SupportTickets.create_support_ticket(valid_attrs)
      assert support_ticket.category == :suggestion
      assert support_ticket.closed_at == ~U[2023-04-03 11:09:00Z]
      assert support_ticket.department == "some department"
      assert support_ticket.description == "some description"
      assert support_ticket.email == "some email"
      assert support_ticket.name == "some name"
      assert support_ticket.opened_at == ~U[2023-04-03 11:09:00Z]
      assert support_ticket.priority == :medium
      assert support_ticket.status == :opened
    end

    test "create_support_ticket/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SupportTickets.create_support_ticket(@invalid_attrs)
    end

    test "update_support_ticket/2 with valid data updates the support_ticket" do
      support_ticket = support_ticket_fixture()

      update_attrs = %{
        category: :suggestion,
        closed_at: ~U[2023-04-04 11:09:00Z],
        department: "some updated department",
        description: "some updated description",
        email: "some updated email",
        name: "some updated name",
        opened_at: ~U[2023-04-04 11:09:00Z],
        priority: :high,
        status: :opened
      }

      assert {:ok, %SupportTicket{} = support_ticket} =
               SupportTickets.update_support_ticket(support_ticket, update_attrs)

      assert support_ticket.category == :suggestion
      assert support_ticket.closed_at == ~U[2023-04-04 11:09:00Z]
      assert support_ticket.department == "some updated department"
      assert support_ticket.description == "some updated description"
      assert support_ticket.email == "some updated email"
      assert support_ticket.name == "some updated name"
      assert support_ticket.opened_at == ~U[2023-04-04 11:09:00Z]
      assert support_ticket.priority == :high
      assert support_ticket.status == :opened
    end

    test "update_support_ticket/2 with invalid data returns error changeset" do
      support_ticket = support_ticket_fixture()
      assert {:error, %Ecto.Changeset{}} = SupportTickets.update_support_ticket(support_ticket, @invalid_attrs)
      assert support_ticket == SupportTickets.get_support_ticket(support_ticket.id)
    end

    test "delete_support_ticket/1 deletes the support_ticket" do
      support_ticket = support_ticket_fixture()
      assert {:ok, %SupportTicket{}} = SupportTickets.delete_support_ticket(support_ticket)
      assert nil == SupportTickets.get_support_ticket(support_ticket.id)
    end

    test "change_support_ticket/1 returns a support_ticket changeset" do
      support_ticket = support_ticket_fixture()
      assert %Ecto.Changeset{} = SupportTickets.change_support_ticket(support_ticket)
    end
  end
end
