defmodule CourtPiece.Repo.Migrations.CreateTableCompletedTurnsHistory do
  use Ecto.Migration

  def change do
    create table(:completed_turns_history, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :turn_number, :integer
      add :cards, {:array, :map}
      add :runing_game_id, references(:runing_games_history, type: :binary_id)

      add :deleted_at, :utc_datetime

      timestamps()
    end
  end
end
