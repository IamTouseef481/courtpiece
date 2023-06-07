defmodule CourtPiece.Repo do
  use Ecto.Repo,
    otp_app: :courtpiece,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  def init(_, config) do
    #    config = config
    #             |> Keyword.put(:username, System.get_env("PGUSER"))
    #             |> Keyword.put(:password, System.get_env("PGPASSWORD"))
    #             |> Keyword.put(:database, System.get_env("PGDATABASE"))
    #             |> Keyword.put(:hostname, System.get_env("PGHOST"))
    #             |> Keyword.put(:port, System.get_env("PGPORT","5432") |> String.to_integer)
    {:ok, config}
  end
end
