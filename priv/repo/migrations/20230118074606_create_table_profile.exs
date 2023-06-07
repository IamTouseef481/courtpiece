defmodule CourtPiece.Repo.Migrations.CreateTableProfile do
  use Ecto.Migration
  import CourtPiece.MigrationHelper

  def up do
    create table(:profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :image_url, :string
      add :level, :integer
      add :total_coins, :integer

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
      full_timestamps()
    end
  end

  def down do
    drop table(:profiles)
  end
end
