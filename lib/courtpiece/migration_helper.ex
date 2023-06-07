defmodule CourtPiece.MigrationHelper do
  use Ecto.Migration
  @moduledoc false
  def full_timestamps do
    add(:deleted_at, :naive_datetime)
  end
end
