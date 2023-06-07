defmodule CourtPiece.SupportTickets.SupportTicket do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "support_tickets" do
    field :category, Ecto.Enum, values: [:complaint, :suggestion, :review, :comment, :other]
    field :closed_at, :utc_datetime
    field :department, :string
    field :description, :string
    field :email, :string
    field :name, :string
    field :opened_at, :utc_datetime
    field :priority, Ecto.Enum, values: [:low, :medium, :high, :highest]
    field :status, Ecto.Enum, values: [:opened, :working_on, :closed, :reopened]

    timestamps()
  end

  @doc false
  def changeset(support_ticket, attrs) do
    support_ticket
    |> cast(attrs, [:name, :description, :status, :email, :priority, :category, :department, :opened_at, :closed_at])
    |> validate_required([:name, :description, :status, :email, :priority, :category, :opened_at])
  end
end
