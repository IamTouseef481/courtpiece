defmodule CourtPiece.Repo.Migrations.CreateSessions do
  use Ecto.Migration
  import CourtPiece.MigrationHelper

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string
      add :user_id, references(:users, type: :binary_id)
      timestamps()
      full_timestamps()
    end
  end
end
