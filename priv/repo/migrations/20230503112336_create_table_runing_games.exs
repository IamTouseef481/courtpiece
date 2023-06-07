defmodule CourtPiece.Repo.Migrations.CreateTableRuningGames do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE runing_game_status AS ENUM ('ready', 'finished', 'not_started')")
    execute("CREATE TYPE visibility AS ENUM ('public', 'private')")

    create table(:runing_games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :current_senior, :binary_id
      add :status, :runing_game_status
      add :visibility, :visibility
      add :trump_suit, :string
      add :game_code, :string
      add :deleted_at, :utc_datetime

      timestamps()
    end
  end
end
