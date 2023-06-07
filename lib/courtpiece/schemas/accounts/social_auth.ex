defmodule CourtPiece.Accounts.SocialAuth do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  @type t :: %__MODULE__{
          id: binary,
          long_token: String.t() | nil,
          user_id: binary
        }

  @required_fields ~w|
    long_token
    user_id
    login_type
  |a

  @optional_fields ~w|
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "social_auths" do
    field :long_token, :string
    field :deleted_at, :naive_datetime
    field :login_type, Ecto.Enum, values: [:facebook, :google, :guest]

    belongs_to(:user, CourtPiece.Accounts.User)

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
