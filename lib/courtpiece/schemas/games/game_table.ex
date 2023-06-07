defmodule CourtPiece.Games.GameTable do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  @type t :: %__MODULE__{
          id: binary,
          bet_value: Integer | nil
        }

  @required_fields ~w|
  bet_value
  game_id
  |a

  @optional_fields ~w|
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "game_tables" do
    field :bet_value, :integer

    field :deleted_at, :naive_datetime

    belongs_to :game, CourtPiece.Games.Game

    timestamps()
  end

  @doc false
  def changeset(game_table, attrs) do
    game_table
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> generate_id()
  end
end
