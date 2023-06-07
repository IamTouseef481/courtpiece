defmodule CourtPiece.Repo.Migrations.AlterTableUserAddColumnSocialId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :social_id, :string
    end

    alter table(:profiles) do
      remove :name
    end
  end
end
