defmodule CourtPiece.Repo.Migrations.CreateTableHands do
  use Ecto.Migration

  def change do
    create table(:hands, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :cards, :map
      add :initial_cards, :map
      add :player_id, :binary_id
      add :runing_game_id, references(:runing_games, type: :binary_id)

      add :deleted_at, :utc_datetime

      timestamps()
    end
  end
end
