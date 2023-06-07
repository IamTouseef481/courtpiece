defmodule CourtPiece.Accounts.Sessions do
  @moduledoc """
  This module defines functions for storing and retrieving session
  """

  import Ecto.Query, warn: false

  alias CourtPiece.Accounts.Session
  alias CourtPiece.Repo
  alias CourtPiece.Token

  def query do
    from(s in Session,
      where: is_nil(s.deleted_at)
    )
  end

  def get_by(id) do
    query()
    |> where([s], s.id == ^id)
    |> Repo.one()
  end

  def get_by_user(user_id) do
    query()
    |> where([s], s.user_id == ^user_id)
    |> Repo.one()
  end

  def get_by_device(device_id) do
    query()
    |> where([s], s.device_id == ^device_id)
    |> Repo.one()
  end

  def create_session(attrs \\ %{}) do
    {:ok, token} = Token.sign(%{device_id: attrs[:device_id], user_id: attrs[:user_id]})
    params = Map.put(attrs, :token, token)

    %Session{}
    |> Session.changeset(params)
    |> Repo.insert()
  end

  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  def get_or_create_session(user_id, %{} = attrs) do
    case get_by_device(attrs[:device_id]) do
      nil ->
        if session = get_by_user(user_id) do
          delete_session(session)
        end

        create_session(attrs)

      session ->
        if session.user_id != user_id do
          {:ok, session}
        else
          delete_session(session)
          create_session(attrs)
        end
    end
  end
end
