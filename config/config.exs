# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :courtpiece,
  ecto_repos: [CourtPiece.Repo],
  generators: [binary_id: true]

host = System.get_env("SERVER_HOST") || "localhost"
# Configures the endpoint
config :courtpiece, CourtPieceWeb.Endpoint,
  url: [host: host],
  render_errors: [view: CourtPieceWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: CourtPiece.PubSub,
  live_view: [signing_salt: "EcK525QP"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :courtpiece, CourtPiece.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix_swagger, json_library: Jason

# Configures swagger
config :courtpiece, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      # phoenix routes will be converted to swagger paths
      router: CourtPieceWeb.Router,
      # (optional) endpoint config used to set host, port and https schemes
      endpoint: CourtPieceWeb.Endpoint
    ]
  }

if Mix.env() == :dev do
  config :git_hooks,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix compile --warnings-as-errors"},
          {:cmd, "mix format --check-formatted"},
          {:cmd, "mix credo --strict"}
        ]
      ],
      pre_push: [
        tasks: [
          {:cmd, "mix clean"},
          {:cmd, "mix compile --warnings-as-errors"},
          {:cmd, "mix format --check-formatted"},
          {:cmd, "mix credo --strict"},
          {:cmd, "mix dialyzer"}
        ]
      ]
    ]
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
