defmodule CourtPiece.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import CourtPiece.Schemas.SchemaHelper, only: [generate_id: 1]

  @type t :: %__MODULE__{
          id: binary,
          name: String.t() | nil,
          email: String.t() | nil,
          user_role: String.t() | nil,
          social_id: String.t() | nil
        }

  @required_fields ~w|
    email
    name
    user_role
  |a

  @optional_fields ~w|
  social_id
  |a

  @all_fields @required_fields ++ @optional_fields
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @moduledoc false
  schema "users" do
    field :name, :string
    field :email, :string
    field :user_role, :string
    field :social_id, :string
    field :deleted_at, :naive_datetime

    has_many :social_auths, CourtPiece.Accounts.SocialAuth, foreign_key: :user_id
    has_one :profile, CourtPiece.Players.Profile, foreign_key: :user_id
    has_one :session, CourtPiece.Accounts.Session, foreign_key: :user_id

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> generate_id()
    |> validate_email(:email)
    |> unique_constraint(:email)
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, @all_fields)
  end

  defp validate_email(%{changes: changes} = changeset, field) do
    changeset = validate_format(changeset, field, ~r/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/)

    if changes[field] == "" do
      changeset
    else
      update_in(
        changeset.errors,
        &Enum.map(&1, fn
          {:email, {"has invalid format", val}} ->
            {:email, {"You've entered an invalid email address, please enter a valid email address to continue", val}}

          {key, val} ->
            {key, val}
        end)
      )
    end
  end
end
