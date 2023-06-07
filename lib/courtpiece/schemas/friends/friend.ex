defmodule CourtPiece.Friends.Friend do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias CourtPiece.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "friends" do
    field :status, Ecto.Enum, values: [:pending, :accepted, :rejected, :ignored]
    belongs_to :request_from, User
    belongs_to :request_to, User
    field :deleted_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(friend, attrs) do
    friend
    |> cast(attrs, [:status, :request_from_id, :request_to_id, :deleted_at])
    |> validate_required([:status, :request_from_id, :request_to_id])
  end
end
