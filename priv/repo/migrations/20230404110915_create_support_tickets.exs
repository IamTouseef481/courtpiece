defmodule CourtPiece.Repo.Migrations.CreateSupportTickets do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE ticket_status AS ENUM ('opened', 'working_on', 'closed', 'reopened')")
    execute("CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'highest')")

    execute(
      "CREATE TYPE ticket_category AS ENUM ('complaint', 'suggestion', 'review', 'comment', 'other')"
    )

    create table(:support_tickets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :email, :string
      add :description, :string
      add :status, :ticket_status
      add :priority, :ticket_priority
      add :category, :ticket_category
      add :department, :string
      add :opened_at, :utc_datetime
      add :closed_at, :utc_datetime

      timestamps()
    end
  end
end
