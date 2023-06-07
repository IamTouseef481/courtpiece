defmodule CourtPiece.Repo.Migrations.CreateTableTeamsHistory do
  use Ecto.Migration

  def change do
    create table(:teams_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_number, :string
      add :player_id, :binary_id
      add :points, :integer
      add :bet_value, :integer
      add :runing_game_id, references(:runing_games_history, type: :binary_id)
      add :game_id, references(:games, type: :binary_id)
      add :deleted_at, :utc_datetime

      timestamps()
    end
  end
end
