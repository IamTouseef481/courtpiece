defmodule CourtPiece.Games.RuningGame do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w|
  status
  visibility
  game_code
  |a

  @optional_fields ~w|
  deleted_at
  current_senior
  trump_suit
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "runing_games" do
    field :current_senior, :binary_id

    field :trump_suit, :string

    field :game_code, :string

    field :visibility, Ecto.Enum, values: [:public, :private]

    field :status, Ecto.Enum, values: [:not_started, :ready, :finished]

    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(runing_game, attrs) do
    runing_game
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
