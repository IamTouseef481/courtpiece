defmodule CourtPiece.Schemas.SchemaHelper do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false

  @spec generate_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def generate_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        put_change(changeset, :id, Ecto.UUID.generate())

      _value ->
        changeset
    end
  end
end
