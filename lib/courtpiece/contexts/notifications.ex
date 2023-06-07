defmodule CourtPiece.Notifications do
  @moduledoc """
  The Notifications context.
  """
  import Ecto.Query, warn: false

  alias CourtPiece.Accounts.User
  alias CourtPiece.Friends.Friend
  alias CourtPiece.Notifications.Notification
  alias CourtPiece.Players.Profile
  alias CourtPiece.Repo

  defp query do
    from(p in Notification,
      where: is_nil(p.deleted_at)
    )
  end

  def list do
    query()
    |> Repo.all()
  end

  def paginate_notifications(user_id, page \\ 1, page_size \\ 10) do
    result =
      query()
      |> join(:left, [n], f in Friend, on: f.id == n.resource_id and n.type == ^:friend_request)
      |> join(:inner, [_, f], u in User, on: u.id == f.request_from_id)
      |> join(:inner, [_, f], p in Profile, on: p.user_id == f.request_from_id)
      |> where([n, _, _], n.is_read == ^false)
      |> where([_, f, _], f.request_to_id == ^user_id)
      |> order_by([n, ...], desc: n.inserted_at)
      |> select([n, f, u, p], %{
        id: n.id,
        message: n.message,
        type: n.type,
        is_opened: n.is_opened,
        is_read: n.is_read,
        inserted_at: n.inserted_at,
        friend_request: %{
          friend_rquest_id: f.id,
          sender_id: u.id,
          sender_name: u.name,
          sender_image_url: p.image_url,
          friend_request_status: f.status
        }
      })
      |> Repo.paginate(page: page, page_size: page_size)

    Map.put(result, :unread_notifications_count, get_unread_notifications_count(user_id))
  end

  def get_notification_by_id(id) do
    query()
    |> join(:inner, [n], f in Friend, on: f.id == n.resource_id)
    |> join(:inner, [_, f], u in User, on: u.id == f.request_from_id)
    |> join(:inner, [_, f], p in Profile, on: p.user_id == f.request_from_id)
    |> where([n], n.id == ^id)
    |> select([n, f, u, p], %{
      id: n.id,
      message: n.message,
      type: n.type,
      is_opened: n.is_opened,
      is_read: n.is_read,
      inserted_at: n.inserted_at,
      friend_request: %{
        friend_request_id: f.id,
        sender_id: u.id,
        sender_name: u.name,
        sender_image_url: p.image_url,
        friend_request_status: f.status
      }
    })
    |> Repo.one()
  end

  def create_notification(params) do
    %Notification{}
    |> Notification.changeset(params)
    |> Repo.insert()
  end

  def update_notification(notification, params) do
    notification
    |> Notification.changeset(params)
    |> Repo.update()
  end

  def get!(id), do: Repo.get!(Notification, id)

  def get_by!(opts) when is_list(opts) do
    Repo.get_by!(Notification, opts)
  end

  def get_unread_notifications_count(user_id) do
    query()
    |> join(:left, [n], f in Friend, on: f.id == n.resource_id and n.type == ^:friend_request)
    |> join(:inner, [_, f], u in User, on: u.id == f.request_from_id)
    |> where([n, _, _], n.is_read == ^false)
    |> where([_, f, _], f.request_to_id == ^user_id)
    |> select([n, ...], count(n.id))
    |> Repo.one()
  end
end
