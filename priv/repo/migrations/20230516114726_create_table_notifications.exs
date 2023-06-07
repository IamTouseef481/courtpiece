defmodule CourtPiece.Repo.Migrations.CreateTableNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :message, :string
      add :type, :string
      add :resource_id, :binary_id
      add :is_read, :boolean, default: false
      add :is_opened, :boolean, default: false
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create unique_index(:notifications, [:type, :resource_id])
  end
end
