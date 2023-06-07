defmodule CourtPiece.Accounts.Session do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  alias CourtPiece.Accounts.User

  @type t :: %__MODULE__{
          id: binary,
          token: String.t() | nil,
          user_id: binary
        }

  @required_fields ~w|
    token
    user_id
    device_id
  |a

  @optional_fields ~w|
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "sessions" do
    field :token, :string
    field :device_id, :string
    belongs_to :user, User

    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> generate_id()
    |> unique_constraint(:device_id)
  end
end
