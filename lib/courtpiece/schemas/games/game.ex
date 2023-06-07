defmodule CourtPiece.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  @type t :: %__MODULE__{
          id: binary,
          name: String.t() | nil,
          title: String.t() | nil
        }

  @required_fields ~w|
  name
  title
  |a

  @optional_fields ~w|
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "games" do
    field :name, :string
    field :title, :string

    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> generate_id()
  end
end
