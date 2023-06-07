defmodule CourtPiece.Schemas.Statistics do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: binary,
          games_played: integer | 0,
          games_won: integer | 0,
          games_lost: integer | 0,
          last_games: list(String.t()) | [],
          user_id: binary
        }

  @required_fields ~w|
    user_id
  |a

  @optional_fields ~w|
      games_played
      games_won
      games_lost
      last_games
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "statistics" do
    field :games_played, :integer, default: 0
    field :games_won, :integer, default: 0
    field :games_lost, :integer, default: 0
    field :last_games, {:array, :string}, default: []

    belongs_to :user, CourtPiece.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(stats, attrs) do
    stats
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
