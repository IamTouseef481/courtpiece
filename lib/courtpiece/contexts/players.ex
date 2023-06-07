defmodule CourtPiece.Players do
  @moduledoc """
  The Players context.
  """

  alias CourtPiece.Players.Profile
  import Ecto.Query, warn: false

  alias CourtPiece.Repo

  defp query do
    from(p in Profile,
      where: is_nil(p.deleted_at)
    )
  end

  def get_by(user_id) do
    query()
    |> where([q], q.user_id == ^user_id)
    |> preload(:user)
    |> Repo.one()
  end

  def create_profile(attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.update_changeset(attrs)
    |> Repo.update()
  end
end
