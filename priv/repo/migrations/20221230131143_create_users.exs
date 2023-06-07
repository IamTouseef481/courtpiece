defmodule CourtPiece.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import CourtPiece.MigrationHelper

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :email, :string
      timestamps()
      full_timestamps()
    end
  end
end
