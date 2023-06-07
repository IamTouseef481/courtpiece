defmodule CourtPiece.Hands.HandHistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias CourtPiece.Games.RuningGameHistory

  @required_fields ~w|
  player_id
  runing_game_id
  |a

  @optional_fields ~w|
  cards
  initial_cards
  deleted_at
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "hands_history" do
    field :cards, :map

    field :initial_cards, :map

    field :player_id, :binary_id

    belongs_to :runing_game, RuningGameHistory

    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(hand, attrs) do
    hand
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
