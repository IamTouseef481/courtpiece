defmodule CourtPiece.Players.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  @type t :: %__MODULE__{
          id: binary,
          image_url: String.t() | nil,
          level: integer | 0,
          total_coins: integer | 0,
          user_id: binary
        }

  @required_fields ~w|
    level
    total_coins
    user_id
  |a

  @optional_fields ~w|
      image_url
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "profiles" do
    field :image_url, :string
    field :level, :integer, default: 0
    field :total_coins, :integer, default: 0

    belongs_to :user, CourtPiece.Accounts.User

    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> add_image_url_and_coins()
    |> generate_id()
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> generate_id()
  end

  def add_image_url_and_coins(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
    if Map.get(changes, :image_url) do
      changeset
    else
      put_change(
        changeset,
        :image_url,
        "https://s3.amazonaws.com/tudodev/2023/5/9/services/original/1683628215678494_profile.svg"
      )
    end
    |> put_change(
      :total_coins,
      5000
    )
  end
end
