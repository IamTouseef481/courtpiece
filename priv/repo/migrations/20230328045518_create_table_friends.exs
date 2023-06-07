defmodule CourtPiece.Repo.Migrations.CreateTableFriends do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE friend_request_status AS ENUM ('pending', 'accepted', 'rejected', 'ignored')"
    )

    create table(:friends, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :friend_request_status
      add :request_from_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :request_to_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create index(:friends, [:request_from_id])
    create index(:friends, [:request_to_id])
  end
end
