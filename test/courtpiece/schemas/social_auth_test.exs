defmodule CourtPiece.Accounts.SocialAuthTest do
  use CourtPiece.DataCase, async: true

  alias CourtPiece.Accounts
  alias CourtPiece.Factory

  describe "social_auths" do
    setup do
      params = Factory.social_auth_factory() |> Map.from_struct()

      {:ok, params: params}
    end

    test "login_type can't be blank", context do
      params = Map.delete(context[:params], :login_type)

      assert {:error, %Ecto.Changeset{errors: [{:login_type, {_, [validation: :required]}}]}} =
               Accounts.create_social_auth(params)
    end

    test "long_token can't be blank", context do
      params = Map.delete(context[:params], :long_token)

      assert {:error, %Ecto.Changeset{errors: [{:long_token, {_, [validation: :required]}}]}} =
               Accounts.create_social_auth(params)
    end

    test "user_id can't be blank", context do
      params = Map.delete(context[:params], :user_id)

      assert {:error, %Ecto.Changeset{errors: [{:user_id, {_, [validation: :required]}}]}} =
               Accounts.create_social_auth(params)
    end
  end
end
