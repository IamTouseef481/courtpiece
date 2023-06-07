defmodule CourtPiece.Accounts.Guest do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  @type t :: %__MODULE__{
          id: binary,
          user_role: String.t() | nil
        }

  @required_fields ~w|
    user_role
  |a

  @optional_fields ~w|
    name
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "users" do
    field :name, :string
    field :user_role, :string
    field :deleted_at, :naive_datetime

    has_many :social_auths, CourtPiece.Accounts.SocialAuth, foreign_key: :user_id
    has_one :profile, CourtPiece.Players.Profile, foreign_key: :user_id

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> generate_id()
  end
end
