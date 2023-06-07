defmodule CourtPiece.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Sage

  alias CourtPiece.Accounts
  alias CourtPiece.Accounts.Guest
  alias CourtPiece.Accounts.SocialAuth
  alias CourtPiece.Accounts.User
  alias CourtPiece.Contexts.Statistics
  alias CourtPiece.Players
  alias CourtPiece.Repo

  defp query do
    from(u in User,
      where: is_nil(u.deleted_at)
    )
  end

  def get_user!(id), do: Repo.get!(query(), id)
  def get_user(id), do: Repo.get(query(), id)

  def get_user(id, device_id) do
    query()
    |> join(:left, [u], s in assoc(u, :session))
    |> where([u, s], u.id == ^id and s.device_id == ^device_id)
    |> select([u], map(u, [:id, :name, :email]))
    |> Repo.one()
  end

  def get_fb_social_auth!(%{user_id: user_id}), do: Repo.get_by!(SocialAuth, user_id: user_id, login_type: :facebook)
  def get_fb_social_auth(%{user_id: user_id}), do: Repo.get_by(SocialAuth, user_id: user_id, login_type: :facebook)

  def get_user_for_broadcasting_on_game_table(ids) when is_list(ids) do
    query()
    |> join(:left, [u], s in assoc(u, :profile))
    |> where([u, _p], u.id in ^ids)
    |> select([u, p], %{id: u.id, name: u.name, imageUrl: p.image_url})
    |> Repo.all()
  end

  def get_user_for_broadcasting_on_game_table(id) do
    query()
    |> join(:left, [u], s in assoc(u, :profile))
    |> where([u, p], u.id == ^id)
    |> select([u], map(u, [:id, :name]))
    |> select_merge([_, p], map(p, [:image_url]))
    |> Repo.one()
    |> case do
      %{} = user -> %{id: user[:id], name: user[:name], imageUrl: user[:image_url]}
      _ -> nil
    end
  end

  def get_user_auth(email, login_type) do
    query()
    |> where([u], u.email == ^email)
    |> join(:left, [u], s in subquery(SocialAuth |> where([s], s.login_type == ^login_type)), on: u.id == s.user_id)
    |> select([u, _], map(u, [:id, :name, :email]))
    |> select_merge([_, s], %{s_auth_id: s.id})
    |> Repo.one()
  end

  def get_by_device(user_role, device_id) do
    query()
    |> join(:left, [u], s in assoc(u, :session))
    |> where([u, s], s.device_id == ^device_id and u.user_role == ^user_role)
    |> select([u, _], map(u, [:id, :name, :email, :user_role]))
    |> select_merge([_, s], %{session_id: s.id, device_id: s.device_id})
    |> Repo.one()
  end

  def get_latest_user do
    from(u in User,
      where: u.user_role in ["guest"],
      order_by: [desc: u.inserted_at],
      select: u.name,
      limit: 1
    )
    |> Repo.one()
  end

  def search_users(params) do
    query()
    |> join(:left, [u], p in assoc(u, :profile))
    |> where_clauses(params)
    |> select([u, _], map(u, [:id, :name, :email]))
    |> select_merge([_, p], %{image_url: p.image_url, total_coins: p.total_coins, level: p.level})
    |> Repo.all()
  end

  def get_or_create_guest_profile(maybe_user, attrs) do
    case maybe_user do
      nil ->
        new()
        |> run(:user, &create_user/2)
        |> run(:player_profile, &create_profile/2)
        |> run(:player_stats, &Statistics.create_empty_stats/2)
        |> transaction(Repo, attrs)

      user ->
        profile = Players.get_by(user[:id])
        {:ok, nil, %{user: user, player_profile: profile}}
    end
  end

  def fill_name(nil) do
    case Accounts.get_latest_user() do
      nil ->
        "guest_1"

      name ->
        number_to_add_prev = String.split(name, "_") |> List.last()

        number_to_add =
          case Integer.parse(number_to_add_prev) do
            {num, _} when is_integer(num) -> num + 1
            _ -> 1
          end

        "guest_#{number_to_add}"
    end
  end

  def fill_name(name), do: name

  @spec create_user_profile(false | nil | maybe_improper_list | map, any) ::
          {:error, any} | {:ok, any, map}
  def create_user_profile(user_params, attrs) do
    cond do
      user_params && user_params[:s_auth_id] ->
        {:ok, nil, %{user: user_params}}

      user_params ->
        params = update_in(attrs[:user_data], &Map.put(&1, :id, user_params.id))

        new()
        |> run(:social_auth, &create_social_auth/2)
        |> transaction(Repo, params)

      true ->
        new()
        |> run(:user, &create_user/2)
        |> run(:social_auth, &create_social_auth/2)
        |> run(:player_profile, &create_profile/2)
        |> run(:player_stats, &Statistics.create_empty_stats/2)
        |> transaction(Repo, attrs)
    end
  end

  def create_user(attrs \\ %{})
  @spec create_user(attrs :: map()) :: {:ok, any()} | {:error, any()}
  def create_user(%{user_role: "guest"} = attrs) do
    %Guest{}
    |> Guest.changeset(attrs)
    |> Repo.insert()
  end

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  defp create_user(_, %{user_data: attrs}) do
    Map.merge(attrs, %{name: fill_name(attrs[:name])})
    |> create_user()
  end

  def update_user(%User{} = user, attrs) do
    user |> User.update_changeset(attrs) |> Repo.update()
  end

  @spec create_social_auth(map(), map()) :: {:ok, map()} | {:error, any()}
  defp create_social_auth(%{user: user}, %{social_auth_data: attrs}) do
    attrs |> Map.put(:user_id, user.id) |> create_social_auth()
  end

  defp create_social_auth(_effects_so_far, %{user_data: %{id: id}, social_auth_data: attrs}) do
    Map.put(attrs, :user_id, id) |> create_social_auth()
  end

  @spec create_social_auth(attrs :: map()) :: {:ok, any()} | {:error, any()}
  def create_social_auth(attrs \\ %{}) do
    %SocialAuth{}
    |> SocialAuth.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_profile(map(), map()) :: {:ok, any()} | {:error, any()}
  defp create_profile(%{user: user}, %{profile_data: attrs}) do
    Map.put(attrs, :user_id, user.id) |> Players.create_profile()
  end

  defp create_profile(_effects_so_far, %{user_data: %{id: id}, profile_data: attrs}) do
    Map.put(attrs, :user_id, id) |> Players.create_profile()
  end

  defp where_clauses(initial_query, params) do
    initial_query =
      if Map.get(params, "id") do
        initial_query
        |> where([u], u.id == ^params["id"])
      else
        initial_query
      end

    if Map.get(params, "search") do
      initial_query
      |> where([u], ilike(u.name, ^"%#{params["search"]}%"))
      |> or_where([u], ilike(u.email, ^"%#{params["search"]}%"))
    else
      initial_query
    end
  end

  def get_by_social_ids(social_ids) do
    from(u in User)
    |> join(:left, [u], s in assoc(u, :social_auths))
    |> join(:left, [u, s], p in assoc(u, :profile))
    |> where([u, s], s.login_type == :facebook and u.social_id in ^social_ids)
    |> select([u, _, p], %{email: u.email, name: u.name, image_url: p.image_url})
    |> Repo.all()
  end
end
