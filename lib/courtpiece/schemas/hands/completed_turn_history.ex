defmodule CourtPiece.Hands.CompletedTurnHistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias CourtPiece.Games.RuningGameHistory

  @required_fields ~w|
  turn_number
  runing_game_id
  cards
  |a

  @optional_fields ~w|
  deleted_at
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "completed_turns_history" do
    field :cards, {:array, :map}

    field :turn_number, :integer

    field :deleted_at, :naive_datetime

    belongs_to :runing_game, RuningGameHistory

    timestamps()
  end

  @doc false
  def changeset(completed_turn, attrs) do
    completed_turn
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
