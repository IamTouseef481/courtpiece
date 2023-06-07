defmodule CourtPieceWeb.Router do
  use CourtPieceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug CourtPiece.Plug.Authenticate
  end

  scope "/api", CourtPieceWeb do
    pipe_through :api

    post "/auth/login/social", SessionController, :new_social
    post "/auth/login/guest", SessionController, :new_guest
    get "/games", DashboardController, :get_game_types

    #    Support Tickets
    resources "/support-tickets", SupportTicketController, [:index, :create, :update]
  end

  scope "/api", CourtPieceWeb do
    pipe_through [:api, :authenticated]

    #    Friends section
    get "/search-users", FriendController, :search_users
    post "/friend-request", FriendController, :send_friend_request
    get "/friend-requests", FriendController, :friend_requests
    put "/friend-request", FriendController, :update_friend_request
    get "/friends", FriendController, :friend_list
    get "/fb-friends", FriendController, :fb_friend_list
    delete "/delete-friends", FriendController, :delete_friend
    resources "/notifications", NotificationController, only: [:index]
  end

  scope "/api" do
    forward "/docs",
            PhoenixSwagger.Plug.SwaggerUI,
            otp_app: :courtpiece,
            disable_validator: false,
            swagger_file: "swagger.json"
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
