defmodule CourtPiece.AccountsTest do
  use CourtPiece.DataCase, async: true

  alias CourtPiece.Accounts
  alias CourtPiece.Factory
  import CourtPiece.AccountsFixtures

  setup do
    valid_attrs = %{name: "test", email: "test@test.com", user_role: "social"}
    invalid_attrs = %{name: "test"}

    {:ok, valid_attrs: valid_attrs, invalid_attrs: invalid_attrs}
  end

  describe "users" do
    test "get_user!/1 returns one user", context do
      user = user_fixture(context[:valid_attrs])
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user_auth/2 returns user info", context do
      user = user_fixture(context[:valid_attrs])
      social_auth = social_auth_fixture(%{user_id: user.id, login_type: "facebook"})

      assert Accounts.get_user_auth(user.email, "facebook") == %{
               id: user.id,
               name: user.name,
               email: user.email,
               s_auth_id: social_auth.id
             }
    end
  end

  describe "create_social_auth/1" do
    test "creates social auth", context do
      user = user_fixture(context[:valid_attrs])
      params = Factory.social_auth_factory() |> Map.from_struct() |> Map.put(:user_id, user.id)
      assert {:ok, %Accounts.SocialAuth{}} = Accounts.create_social_auth(params)
    end

    test "create_social_auth/1 creates social_auth", context do
      user = user_fixture(context[:valid_attrs])
      params = Factory.social_auth_factory() |> Map.from_struct() |> Map.put(:user_id, user.id)
      assert {:ok, %Accounts.SocialAuth{}} = Accounts.create_social_auth(params)
    end
  end

  describe "create_users/2" do
    test "creates valid user", context do
      assert {:ok, %Accounts.User{}} = Accounts.create_user(context[:valid_attrs])
    end

    test " invalid user", context do
      assert {
               :error,
               %Ecto.Changeset{
                 errors: [
                   email: {_, [validation: :required]},
                   user_role: {_, [validation: :required]}
                 ]
               }
             } = Accounts.create_user(context[:invalid_attrs])
    end
  end

  describe "create_user_profile/2" do
    setup do
      params = %{
        user_data: Factory.user_factory() |> Map.from_struct(),
        social_auth_data: Factory.social_auth_factory() |> Map.from_struct(),
        profile_data: Factory.profile_factory() |> Map.from_struct()
      }

      {:ok, params: params}
    end

    test "creates valid user, auth and profile", params do
      params = params[:params]

      assert {:ok, _, %{user: _user, social_auth: _sauth, player_profile: _p_profile}} =
               Accounts.create_user_profile(false, params)
    end

    #    test "creates valid user_auth and profile", params do
    #      params = params[:params]
    #      Accounts.create_user_profile(false, params)
    #      new_type = Enum.reject(["facebook", "google"], &(&1 == params[:social_auth_data][:login_type])) |> List.first
    #
    #      user = Accounts.get_user_auth(params[:user_data][:email], new_type)
    #      params = update_in(params[:social_auth_data][:login_type], fn _x -> new_type end)
    #
    #      Accounts.test()
    #
    #      assert {:ok, _, %{social_auth: _s_auth}} = Accounts.create_user_profile(user, params)
    #    end

    test "returns already existed user", params do
      params = params[:params]
      Accounts.create_user_profile(false, params)

      user = Accounts.get_user_auth(params[:user_data][:email], params[:social_auth_data][:login_type])

      assert {:ok, _, %{user: _user}} = Accounts.create_user_profile(user, params)
    end
  end
end
