defmodule CourtPiece.Repo.Migrations.CreateTableGame do
  use Ecto.Migration

  import CourtPiece.MigrationHelper

  def up do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :title, :string

      timestamps()
      full_timestamps()
    end
  end

  def down do
    drop table(:games)
  end
end
