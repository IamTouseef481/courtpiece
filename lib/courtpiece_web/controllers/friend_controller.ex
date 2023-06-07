defmodule CourtPieceWeb.FriendController do
  use CourtPieceWeb, :controller
  action_fallback(CourtPieceWeb.SessionFallbackController)

  alias CourtPiece.{Accounts, Friends}
  alias CourtPiece.Friends.Friend
  alias CourtPiece.Notifications
  alias CourtPiece.SocialHelpers
  alias CourtPieceWeb.CommonParameters

  use PhoenixSwagger

  swagger_path :search_users do
    get("/search-users")
    produces("application/json")
    security([%{Bearer: []}])
    description("Search Users for friend invitation")

    parameters do
      search(:query, :string, "Search - Email | Name")
      id(:query, :string, "Id")
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def search_users(conn, params) do
    #    add pagination
    response = Accounts.search_users(params)

    conn
    |> put_status(200)
    |> render("search_users.json", %{user_data: response})
  end

  swagger_path :send_friend_request do
    post("/friend-request")
    produces("application/json")
    security([%{Bearer: []}])
    description("Send friend request to multiple users at a time")

    parameters do
      body(:body, Schema.ref(:SendFriendRequest), "User ids")
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def send_friend_request(conn, %{"user_ids" => user_ids}) do
    from_id = conn.assigns.current_user.id

    response =
      Enum.reduce(
        user_ids,
        [],
        fn to_id, acc ->
          params = %{request_from_id: from_id, request_to_id: to_id, status: :pending}

          case Friends.get_friend_request(params) do
            %Friend{status: :accepted, deleted_at: nil} ->
              [%{user_id: to_id, message: "Already friend"} | acc]

            %Friend{status: :pending} ->
              [%{user_id: to_id, message: "Request already sent"} | acc]

            %Friend{status: status} = friend when status in [:rejected, :ignored] ->
              Friends.update_friend(friend, params)
              [%{user_id: to_id, message: "Request sent"} | acc]

            %Friend{status: :accepted} = friend ->
              Friends.update_friend(friend, Map.merge(params, %{deleted_at: nil}))
              [%{user_id: to_id, message: "Request sent"} | acc]

            nil ->
              {:ok, request} = Friends.create_friend(params)
              params = fetch_notification_params(request.id, conn.assigns.current_user.name)
              {:ok, notification} = Notifications.create_notification(params)
              sender = Accounts.get_user_for_broadcasting_on_game_table(from_id)

              CourtPieceWeb.Endpoint.broadcast(
                "user:" <> to_string(to_id),
                "friend_request_received",
                fetch_response(notification, request, sender)
              )

              [%{user_id: to_id, message: "Request sent"} | acc]
          end
        end
      )

    conn
    |> put_status(200)
    |> render("friend_requests.json", %{data: response})
  rescue
    _ -> {:error, "Unable to send friend request"}
  end

  swagger_path :friend_requests do
    get("/friend-requests")
    produces("application/json")
    security([%{Bearer: []}])
    description("Fetch friend requests")

    response(200, "success")
    response(401, "unauthorized")
  end

  def friend_requests(conn, _) do
    from_id = conn.assigns.current_user.id
    friend_requests = Friends.list_friends(%{"request_from_id" => from_id, "status" => :pending})

    conn
    |> put_status(200)
    |> render("friend_requests.json", %{data: friend_requests})
  end

  swagger_path :update_friend_request do
    put("/friend-request")
    produces("application/json")
    security([%{Bearer: []}])
    description("Perform actions on a friend request")

    parameters do
      user_id(:query, :string, "User id", required: true)

      status(
        :query,
        :array,
        "Accept, Decline, Ignore request",
        required: true,
        items: [
          type: :string,
          enum: ["accepted", "rejected", "ignored"]
        ]
      )
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def update_friend_request(conn, %{"user_id" => user_id, "status" => status}) do
    from_id = conn.assigns.current_user.id

    params = %{request_from_id: from_id, request_to_id: user_id, status: status}

    response =
      case Friends.get_friend_request(params) do
        %Friend{status: :pending} = friend ->
          if status in ["rejected", "ignored", "accepted"] do
            Friends.update_friend(friend, params)
            # Broadcast will only be sent in case of accepted friend request case
            send_approval_broadcast(status, user_id)
            # If any of the action is performed then the notification status will be updated i.e is_read= true
            update_notification_status(friend)
            %{message: "Request updated successfully"}
          else
            %{message: "Request can not be updated"}
          end

        %Friend{status: :accepted} ->
          %{message: "Already friend"}

        %Friend{status: status} when status in [:rejected, :ignored] ->
          %{message: "Request can not be updated"}

        nil ->
          %{message: "Request does not exit"}
      end

    conn
    |> put_status(200)
    |> render("update_friend_request.json", %{data: response})
  rescue
    _ -> {:error, "Unable to update friend equest"}
  end

  swagger_path :friend_list do
    get("/friends")
    produces("application/json")
    security([%{Bearer: []}])
    description("Friend list")

    parameters do
      search(:query, :string, "Name | Email")
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def friend_list(conn, params) do
    from_id = conn.assigns.current_user.id
    params = Map.merge(params, %{"request_from_id" => from_id, "status" => :accepted})
    friends = Friends.list_friends(params)

    conn
    |> put_status(200)
    |> render("friends.json", %{data: friends})
  end

  swagger_path :delete do
    delete("/delete-friends")
    summary("Delete friend")
    description("Delete a friend")
    produces("application/json")
    security([%{Bearer: []}])

    parameters do
      id(:query, :string, "Friend ID", required: true)
    end

    response(200, "Ok")
  end

  def delete_friend(conn, %{"id" => to_id}) do
    from_id = conn.assigns.current_user.id

    case Friends.get_friend_request(%{request_from_id: from_id, request_to_id: to_id}) do
      nil ->
        render(conn, "user.json", %{error: ["Friend not found"]})

      %Friend{status: :accepted, deleted_at: nil} = friend ->
        {:ok, deleted_friend} = Friends.update_friend(friend, %{deleted_at: DateTime.utc_now()})
        render(conn, "delete_friend.json", %{deleted_friend: deleted_friend})

      %Friend{status: :accepted} ->
        render(conn, "user.json", %{error: ["Friend already deleted"]})

      _ ->
        render(conn, "user.json", %{error: ["You cannot delete friend"]})
    end
  end

  defp fetch_notification_params(resource_id, user_name) do
    user_name = user_name || "Someone"
    message = user_name <> " sent you friend request"

    %{
      resource_id: resource_id,
      type: "friend_request",
      message: message
    }
  end

  defp fetch_response(notification, request, sender) do
    %{
      id: notification.id,
      message: notification.message,
      type: notification.type,
      is_opened: notification.is_opened,
      is_read: notification.is_read,
      friend_request: %{
        friend_rquest_id: request.id,
        sender_id: sender.id,
        sender_name: sender.name,
        sender_image_url: sender.imageUrl,
        friend_request_status: request.status
      },
      unread_notifications_count: Notifications.get_unread_notifications_count(request.request_to_id)
    }
  end

  swagger_path :fb_friend_list do
    get("/fb-friends")
    produces("application/json")
    security([%{Bearer: []}])
    description("Facebook friend list")

    parameters do
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def fb_friend_list(conn, _params) do
    with %{login_type: :facebook, long_token: long_token} <-
           Accounts.get_fb_social_auth(%{user_id: conn.assigns.current_user.id}),
         friends <- SocialHelpers.get_user_friends(long_token, "facebook") do
      data = get_fb_friends_data(friends)

      conn
      |> put_status(200)
      |> render("fb_friends.json", %{data: data})
    else
      _ -> render(conn, "fb_friends.json", %{data: []})
    end
  end

  defp get_fb_friends_data(friends) do
    get_ids(friends)
    |> Accounts.get_by_social_ids()
  end

  defp get_ids(friends), do: Enum.map(friends, & &1["id"])

  defp send_approval_broadcast("accepted", user_id) do
    user = Accounts.get_user_for_broadcasting_on_game_table(user_id)
    message = user.name <> " accepted your friend request"

    CourtPieceWeb.Endpoint.broadcast(
      "user:" <> to_string(user_id),
      "friend_request_accepted",
      %{
        message: message,
        user_name: user.name,
        user_id: user.id,
        image_url: user.imageUrl
      }
    )
  end

  defp send_approval_broadcast(_, _), do: :ok

  defp update_notification_status(%Friend{id: id}) do
    notification = Notifications.get_by!(resource_id: id, type: :friend_request)
    Notifications.update_notification(notification, %{is_read: true})
  end

  def swagger_definitions do
    %{
      SearchUserParams:
        swagger_schema do
          title("Search params")
          description("Search params")

          CommonParameters.authorization_props()

          properties do
            user_id(:string, "user's id")
            email(:string, "email")
            name(:string, "user's name")
          end
        end,
      SendFriendRequest:
        swagger_schema do
          title("Send friend request")
          description("Send friend request")

          CommonParameters.authorization_props()

          properties do
            user_ids(:array, "User ids")
          end

          example(%{user_ids: ["f6a88530-6ae5-4f11-b7e5-28a560b9c1cb"]})
        end,
      UpdateFriendRequest:
        swagger_schema do
          title("Update friend request")
          description("Update friend request")

          CommonParameters.authorization_props()
        end
    }
  end
end
