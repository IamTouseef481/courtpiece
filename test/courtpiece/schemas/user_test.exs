defmodule CourtPiece.Accounts.UserTest do
  use CourtPiece.DataCase, async: true

  alias CourtPiece.Accounts
  alias CourtPiece.Factory

  describe "users" do
    import CourtPiece.AccountsFixtures

    test "email must be unique" do
      user_params = Factory.user_factory(user_role: "social") |> Map.from_struct()
      user_fixture(user_params)

      assert {:error, %Ecto.Changeset{errors: [email: {_, [{:constraint, :unique} | [_]]}]}} =
               Accounts.create_user(user_params)
    end
  end
end
