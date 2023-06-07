defmodule CourtPiece.Repo.Migrations.AlterTableUsersAddUserRole do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :user_role, :string
    end
  end
end
