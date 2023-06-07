defmodule CourtPieceWeb.SupportTicketController do
  use CourtPieceWeb, :controller
  action_fallback(CourtPieceWeb.SessionFallbackController)

  alias CourtPiece.SupportTickets
  alias CourtPiece.SupportTickets.SupportTicket
  alias CourtPieceWeb.CommonParameters

  use PhoenixSwagger

  swagger_path :index do
    get("/support-tickets")
    produces("application/json")
    security([%{Bearer: []}])
    description("Fetch support tickets for Admin")

    parameters do
      status(:query, :array, "Opened, Working_on, Closed, Reopened",
        items: [type: :string, enum: ["opened", "working_on", "closed", "reopened"]]
      )

      priority(:query, :array, "Low, Medium, High, Highest",
        items: [type: :string, enum: ["low", "medium", "high", "highest"]]
      )

      category(:query, :array, "Complaint, Suggestion, Review, Comment, Other",
        items: [type: :string, enum: ["complaint", "suggestion", "review", "comment", "other"]]
      )

      name(:query, :string, "User name")
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def index(conn, params) do
    #    pagination is to e applied
    response = SupportTickets.fetch_tickets_for_admin(params)

    conn
    |> put_status(200)
    |> render("tickets.json", %{data: response})
  end

  swagger_path :create do
    post("/support-tickets")
    produces("application/json")
    description("Create support ticket")

    parameters do
      body(
        :body,
        Schema.ref(:createSupportTicket),
        "category should be complaint, suggestion, review, comment or other"
      )
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def create(conn, params) do
    params =
      params
      |> Map.merge(%{"priority" => :high, "status" => :opened, "opened_at" => DateTime.utc_now()})

    case SupportTickets.create_support_ticket(params) do
      {:ok, ticket} ->
        conn
        |> put_status(200)
        |> render("created_ticket.json", %{data: ticket})

      {:error, error} ->
        %{error: error}
    end
  rescue
    _ -> {:error, "Unable to create ticket"}
  end

  swagger_path :update do
    put("/support-tickets/{id}")
    produces("application/json")
    security([%{Bearer: []}])
    description("Update support ticket")

    parameters do
      id(:path, :string, "Ticket id", required: true)
      department(:query, :string, "Department")

      status(:query, :array, "Opened, Working_on, Closed, Reopened",
        items: [type: :string, enum: ["opened", "working_on", "closed", "reopened"]]
      )

      priority(:query, :array, "Low, Medium, High, Highest",
        items: [type: :string, enum: ["low", "medium", "high", "highest"]]
      )
    end

    response(200, "success")
    response(401, "unauthorized")
  end

  def update(conn, %{"id" => id} = params) do
    params = if params["status"] == "closed", do: Map.put(params, "closed_at", DateTime.utc_now()), else: params

    with %SupportTicket{} = ticket <- SupportTickets.get_support_ticket(id),
         {:ok, ticket} <- SupportTickets.update_support_ticket(ticket, params) do
      conn
      |> put_status(200)
      |> render("updated_ticket.json", %{data: ticket})
    else
      nil ->
        %{message: "Ticket not found"}

      _ ->
        %{message: "Ticket not updated"}
    end
  rescue
    _ -> {:error, "Unable to update ticket"}
  end

  def swagger_definitions do
    %{
      createSupportTicket:
        swagger_schema do
          title("Create support ticket")
          description("Create support ticket")

          CommonParameters.authorization_props()

          properties do
            name(:string, "User name")
            email(:string, "Email")
            description(:string, "Ticket description")
            category(:string, "Ticket category")
          end

          example(%{
            name: "Test name",
            email: "test@example.com",
            description: "Hi, I am not able to start game after login",
            category: "complaint"
          })
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
