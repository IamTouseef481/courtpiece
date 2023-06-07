defmodule CourtPiece.Repo.Migrations.CreateTableSocialAuth do
  use Ecto.Migration
  import CourtPiece.MigrationHelper

  def change do
    create table(:social_auths, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :long_token, :string
      add :login_type, :string
      add :user_id, references(:users, type: :binary_id)

      timestamps()
      full_timestamps()
    end
  end
end
