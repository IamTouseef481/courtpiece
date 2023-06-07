defmodule CourtPiece.Friends do
  @moduledoc """
  The Friends context.
  """

  import Ecto.Query, warn: false
  alias CourtPiece.Repo

  alias CourtPiece.Accounts.User
  alias CourtPiece.Friends.Friend
  alias CourtPiece.Players.Profile

  defp query do
    from(f in Friend,
      where: is_nil(f.deleted_at)
    )
  end

  @doc """
  Returns the list of friends.

  ## Examples

      iex> list_friends()s
      [%Friend{}, ...]

  """
  def list_friends do
    Repo.all(Friend)
  end

  @doc """
  Gets a single friend.

  Raises `Ecto.NoResultsError` if the Friend does not exist.

  ## Examples

      iex> get_friend!(123)
      %Friend{}

      iex> get_friend!(456)
      ** (Ecto.NoResultsError)

  """
  def get_friend!(id), do: Repo.get!(Friend, id)

  def get_friend_request(%{request_from_id: from_id, request_to_id: to_id}) do
    Friend
    |> where([f], f.request_from_id == ^from_id and f.request_to_id == ^to_id)
    |> or_where([f], f.request_from_id == ^to_id and f.request_to_id == ^from_id)
    |> Repo.one()
  end

  def list_friends(%{"request_from_id" => from_id, "search" => search_param, "status" => status}) do
    from([f, u] in friends_query(from_id, status),
      where: ilike(u.name, ^"%#{search_param}%"),
      or_where: ilike(u.email, ^"%#{search_param}%")
    )
    |> Repo.all()
  end

  def list_friends(%{"request_from_id" => from_id, "status" => status}) do
    query()

    friends_query(from_id, status)
    |> Repo.all()
  end

  defp friends_query(from_id, status) do
    query()
    |> join(:inner, [f], u in User, on: f.request_from_id == u.id or f.request_to_id == u.id)
    |> join(:left, [_, u], p in Profile, on: p.user_id == u.id)
    |> where([f, ...], (f.request_from_id == ^from_id or f.request_to_id == ^from_id) and f.status == ^status)
    |> where([_, u, _], u.id != ^from_id)
    |> order_by([_, u, _], asc: u.name)
    #    |> distinct([_, u, _], u.id)
    |> select([_, u, _], map(u, [:id, :name, :email]))
    |> select_merge([_, _, p], %{image_url: p.image_url, total_coins: p.total_coins, level: p.level})
  end

  @doc """
  Creates a friend.

  ## Examples

      iex> create_friend(%{field: value})
      {:ok, %Friend{}}

      iex> create_friend(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_friend(attrs \\ %{}) do
    %Friend{}
    |> Friend.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a friend.

  ## Examples

      iex> update_friend(friend, %{field: new_value})
      {:ok, %Friend{}}

      iex> update_friend(friend, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_friend(%Friend{} = friend, attrs) do
    friend
    |> Friend.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a friend.

  ## Examples

      iex> delete_friend(friend)
      {:ok, %Friend{}}

      iex> delete_friend(friend)
      {:error, %Ecto.Changeset{}}

  """
  def delete_friend(%Friend{} = friend) do
    Repo.delete(friend)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking friend changes.

  ## Examples

      iex> change_friend(friend)
      %Ecto.Changeset{data: %Friend{}}

  """
  def change_friend(%Friend{} = friend, attrs \\ %{}) do
    Friend.changeset(friend, attrs)
  end
end
