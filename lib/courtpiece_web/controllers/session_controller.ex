defmodule CourtPieceWeb.SessionController do
  use CourtPieceWeb, :controller
  action_fallback(CourtPieceWeb.SessionFallbackController)

  alias CourtPiece.{Accounts, Games}
  alias CourtPiece.Accounts.Sessions
  alias CourtPiece.Players
  alias CourtPiece.SocialHelpers
  alias CourtPieceWeb.CommonParameters

  use PhoenixSwagger

  swagger_path :new_social do
    post("/auth/login/social")
    produces("application/json")
    security([%{Bearer: []}])
    description("Verifies login credentials")

    parameters do
      body(:body, Schema.ref(:NewSocial), "Login Credentials", required: true)
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def new_social(conn, %{
        "token" => short_token,
        "auth_type" => auth_type,
        "device_id" => device_id
      })
      when auth_type in ["facebook", "google"] do
    user_role = "social"

    with {:ok, %{"access_token" => long_token} = token_params} <-
           SocialHelpers.get_long_token(short_token, auth_type),
         {:ok, %{"email" => email} = social_data} <-
           SocialHelpers.get_user_data(long_token, auth_type),
         maybe_user <- Accounts.get_user_auth(email, auth_type),
         {:ok, _, profile_data} <-
           Accounts.create_user_profile(
             maybe_user,
             %{
               user_data: %{
                 name: social_data["name"],
                 email: social_data["email"],
                 user_role: user_role,
                 social_id: social_data["id"]
               },
               social_auth_data: %{
                 long_token: token_params["access_token"],
                 login_type: auth_type
               },
               profile_data: %{
                 name: social_data["name"],
                 image_url: social_data["picture"]
               }
             }
           ),
         user <- maybe_user || profile_data[:user],
         {:ok, session} <-
           Sessions.get_or_create_session(
             user.id,
             %{
               device_id: device_id,
               user_id: user.id
             }
           ) do
      player_profile =
        case profile_data do
          %{player_profile: profile} -> profile
          _x -> Players.get_by(user.id)
        end

      games = Games.get_all_games()

      user_data = %{
        id: player_profile.user_id,
        name: user.name,
        email: user.email,
        level: player_profile.level,
        total_coins: player_profile.total_coins,
        image_url: player_profile.image_url,
        token: session.token,
        games: games
      }

      conn
      |> put_status(201)
      |> render("new_user.json", %{user_data: user_data})
    else
      x -> x
    end
  rescue
    _ -> {:error, "Unable to Login"}
  end

  def new_social(_conn, %{
        "token" => _,
        "auth_type" => _,
        "device_id" => _
      }) do
    {:error, "auth_type should be facebook or google"}
  end

  def new_social(_conn, _), do: {:error, "Some parameter is missing"}

  swagger_path :new_guest do
    post("/auth/login/guest")
    produces("application/json")
    security([%{Bearer: []}])
    description("Verifies login credentials")

    parameters do
      body(:body, Schema.ref(:NewGuest), "Login Credentials", required: true)
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def new_guest(conn, %{"device_id" => device_id}) do
    user_role = "guest"

    with maybe_user <- Accounts.get_by_device(user_role, device_id),
         {:ok, _, %{user: user, player_profile: profile}} <-
           Accounts.get_or_create_guest_profile(maybe_user, %{
             user_data: %{user_role: user_role},
             profile_data: %{}
           }),
         user <- maybe_user || user,
         {:ok, session} <-
           Sessions.get_or_create_session(
             user.id,
             %{
               device_id: device_id,
               user_id: user.id
             }
           ) do
      games = Games.get_all_games()

      user_data = %{
        id: user.id,
        name: user.name,
        level: profile.level,
        total_coins: profile.total_coins,
        image_url: profile.image_url,
        token: session.token,
        games: games
      }

      conn
      |> put_status(201)
      |> render("new_guest.json", %{user_data: user_data})
    else
      x -> x
    end
  rescue
    _ -> {:error, "Unable to Login"}
  end

  def swagger_definitions do
    %{
      NewSocial:
        swagger_schema do
          title("Generate JWT Token")
          description("Login to the system")

          CommonParameters.authorization_props()

          properties do
            token(:string, "token")
            auth_type(:string, "The authentication type")
          end

          example(%{
            auth_type: "facebook",
            token: "x9NQidbgz1NinEOw7",
            device_id: "5ob92J"
          })
        end,
      NewGuest:
        swagger_schema do
          title("Generate JWT Token")
          description("Login to the system")

          CommonParameters.authorization_props()

          example(%{
            device_id: "5ob92J"
          })
        end
    }
  end
end
