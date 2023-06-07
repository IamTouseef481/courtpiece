defmodule CourtPiece.Repo.Migrations.CreateTableStats do
  use Ecto.Migration

  def up do
    create table(:statistics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :games_played, :integer, default: 0
      add :games_won, :integer, default: 0
      add :games_lost, :integer, default: 0
      add :last_games, {:array, :string}, default: "{}"

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:statistics, [:user_id])
  end

  def down do
    drop table(:statistics)
  end
end
