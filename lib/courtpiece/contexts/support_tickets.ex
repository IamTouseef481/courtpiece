defmodule CourtPiece.SupportTickets do
  @moduledoc """
  The SupportTickets context.
  """

  import Ecto.Query, warn: false
  alias CourtPiece.Repo
  alias CourtPiece.SupportTickets.SupportTicket

  @doc """
  Returns the list of support_tickets.

  ## Examples

      iex> list_support_tickets()
      [%SupportTicket{}, ...]

  """
  def list_support_tickets do
    Repo.all(SupportTicket)
  end

  def fetch_tickets_for_admin(params) do
    query =
      from(t in SupportTicket)
      |> order_by([t], desc: t.status == :opened, desc: t.opened_at)
      |> select(
        [t],
        map(t, [:id, :name, :email, :description, :status, :priority, :category, :department, :opened_at, :closed_at])
      )

    query =
      if params["name"],
        do: from(query |> where([t], ilike(t.name, ^"%#{params["name"]}%"))),
        else: query

    query =
      if params["status"] in ["", nil],
        do: query,
        else: from(query |> where([t], t.status == ^params["status"]))

    query =
      if params["priority"] in ["", nil],
        do: query,
        else: from(query |> where([t], t.priority == ^params["priority"]))

    query =
      if params["category"] in ["", nil],
        do: query,
        else: from(query |> where([t], t.category == ^params["category"]))

    Repo.all(query)
  end

  @doc """
  Gets a single support_ticket.

  Raises `Ecto.NoResultsError` if the Support ticket does not exist.

  ## Examples

      iex> get_support_ticket(123)
      %SupportTicket{}

      iex> get_support_ticket(456)
      ** (Ecto.NoResultsError)

  """
  def get_support_ticket(id), do: Repo.get(SupportTicket, id)

  @doc """
  Creates a support_ticket.

  ## Examples

      iex> create_support_ticket(%{field: value})
      {:ok, %SupportTicket{}}

      iex> create_support_ticket(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_support_ticket(attrs \\ %{}) do
    %SupportTicket{}
    |> SupportTicket.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a support_ticket.

  ## Examples

      iex> update_support_ticket(support_ticket, %{field: new_value})
      {:ok, %SupportTicket{}}

      iex> update_support_ticket(support_ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_support_ticket(%SupportTicket{} = support_ticket, attrs) do
    support_ticket
    |> SupportTicket.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a support_ticket.

  ## Examples

      iex> delete_support_ticket(support_ticket)
      {:ok, %SupportTicket{}}

      iex> delete_support_ticket(support_ticket)
      {:error, %Ecto.Changeset{}}

  """
  def delete_support_ticket(%SupportTicket{} = support_ticket) do
    Repo.delete(support_ticket)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking support_ticket changes.

  ## Examples

      iex> change_support_ticket(support_ticket)
      %Ecto.Changeset{data: %SupportTicket{}}

  """
  def change_support_ticket(%SupportTicket{} = support_ticket, attrs \\ %{}) do
    SupportTicket.changeset(support_ticket, attrs)
  end
end
