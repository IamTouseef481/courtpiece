defmodule CourtPiece.Teams.TeamHistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias CourtPiece.Games.{Game, RuningGameHistory}

  @required_fields ~w|
  runing_game_id
  game_id
  |a

  @optional_fields ~w|
  team_number
  points
  player_id
  deleted_at
  bet_value
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "teams_history" do
    belongs_to :runing_game, RuningGameHistory
    belongs_to :game, Game

    field :player_id, :binary_id

    field :points, :integer

    field :bet_value, :integer

    field :team_number, :string

    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
