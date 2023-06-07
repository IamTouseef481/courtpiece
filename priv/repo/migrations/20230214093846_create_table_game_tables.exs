defmodule CourtPiece.Repo.Migrations.CreateTableGameTables do
  use Ecto.Migration

  import CourtPiece.MigrationHelper

  def up do
    create table(:game_tables, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bet_value, :integer
      add :game_id, references(:games, type: :binary_id)

      timestamps()
      full_timestamps()
    end
  end

  def down do
    drop table(:game_tables)
  end
end
