defmodule CourtPiece.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the Ecto repository
      CourtPiece.Repo,
      # Start the Telemetry supervisor
      CourtPieceWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CourtPiece.PubSub},
      # Start the Endpoint (http/https)
      CourtPieceWeb.Endpoint,
      # Start Presence
      CourtPieceWeb.Presence,
      # Start Supervisor for tracking GameServer
      {CourtPiece.GamesSupervisor, []},
      # Start the Agent for tracking Genserver names
      CourtPiece.GameAgent
      # Start a worker by calling: CourtPiece.Worker.start_link(arg)
      # {CourtPiece.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CourtPiece.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CourtPieceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
