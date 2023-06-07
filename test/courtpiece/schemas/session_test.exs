defmodule CourtPiece.Accounts.SessionTest do
  use CourtPiece.DataCase, async: true

  alias CourtPiece.Accounts.Sessions
  alias CourtPiece.Factory

  describe "sessions" do
    import CourtPiece.AccountsFixtures

    setup do
      user = Factory.user_factory() |> Map.from_struct() |> user_fixture
      params = Factory.session_factory() |> Map.from_struct() |> Map.put(:user_id, user.id)

      {:ok, params: params}
    end

    test "device_id must be unique", context do
      session_fixture(context[:params])

      assert {:error, %Ecto.Changeset{errors: [device_id: {_, [{:constraint, :unique} | [_]]}]}} =
               Sessions.create_session(context[:params])
    end

    test "device_id can't be blank", context do
      params = Map.delete(context[:params], :device_id)

      assert {:error, %Ecto.Changeset{errors: [{:device_id, {_, [validation: :required]}}]}} =
               Sessions.create_session(params)
    end

    test "user_id can't be blank", context do
      params = Map.delete(context[:params], :user_id)

      assert {:error, %Ecto.Changeset{errors: [{:user_id, {_, [validation: :required]}}]}} =
               Sessions.create_session(params)
    end
  end
end
