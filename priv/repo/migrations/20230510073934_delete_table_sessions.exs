defmodule CourtPiece.Repo.Migrations.DeleteTableSessions do
  use Ecto.Migration
  alias CourtPiece.Accounts.Session
  alias alias CourtPiece.Repo

  def change do
    Repo.delete_all(Session)
  end
end
