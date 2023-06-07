defmodule CourtPiece.Notifications.Notification do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @required_fields [:resource_id, :type, :message]
  @optional_fields [:is_read, :is_opened, :deleted_at]

  @all_fields @required_fields ++ @optional_fields

  schema "notifications" do
    field :type, Ecto.Enum, values: [:friend_request, :game_challenge]
    field :message, :string
    field :resource_id, Ecto.UUID
    field :is_read, :boolean, default: false
    field :is_opened, :boolean, default: false
    field :deleted_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
