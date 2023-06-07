defmodule CourtPiece.Repo.Migrations.AlterTableSessionsAddDeviceId do
  use Ecto.Migration

  def change do
    alter table("sessions") do
      add :device_id, :string
    end

    create unique_index(:sessions, :device_id)
  end
end
