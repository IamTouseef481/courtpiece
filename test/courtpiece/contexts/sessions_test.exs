defmodule CourtPiece.SessionsTest do
  use CourtPiece.DataCase, async: true

  alias CourtPiece.Accounts.Session
  alias CourtPiece.Accounts.Sessions
  alias CourtPiece.Factory
  import CourtPiece.AccountsFixtures

  setup do
    user = Factory.user_factory() |> Map.from_struct() |> user_fixture
    valid_attrs = Factory.session_factory() |> Map.from_struct() |> Map.put(:user_id, user.id)
    invalid_attrs = valid_attrs |> Map.delete(:user_id)

    {:ok, valid_attrs: valid_attrs, invalid_attrs: invalid_attrs}
  end

  describe "create_session/1" do
    test "creates valid session", context do
      assert {:ok, %CourtPiece.Accounts.Session{}} = Sessions.create_session(context[:valid_attrs])
    end

    test "user_id can't be blank", context do
      assert {:error, %Ecto.Changeset{errors: [user_id: {_, [validation: :required]}]}} =
               Sessions.create_session(context[:invalid_attrs])
    end
  end

  describe "get_or_create_session/2" do
    test "retrieves valid session", context do
      assert {:ok, %CourtPiece.Accounts.Session{}} =
               Sessions.get_or_create_session(Ecto.UUID.generate(), context[:valid_attrs])
    end

    test "creates valid session", context do
      attrs = context[:valid_attrs]

      assert {:ok, %CourtPiece.Accounts.Session{}} = Sessions.get_or_create_session(attrs[:user_id], attrs)
    end
  end

  describe "get_by_user/1" do
    test "retrieves valid session", context do
      attrs = context[:valid_attrs]
      session = session_fixture(attrs)
      assert ^session = Sessions.get_by_user(attrs[:user_id])
    end

    test "returns nil for no session" do
      assert nil == Sessions.get_by_user(Ecto.UUID.generate())
    end
  end

  describe "get_by_device/1" do
    test "retrieves valid session", context do
      attrs = context[:valid_attrs]
      session = session_fixture(attrs)
      assert ^session = Sessions.get_by_device(attrs[:device_id])
    end

    test "returns nil for no session" do
      assert nil == Sessions.get_by_device(Factory.gen_random_text())
    end
  end

  describe "delete_session/1" do
    test "deletes valid session", context do
      attrs = context[:valid_attrs]
      session = session_fixture(attrs)
      assert {:ok, %Session{}} = Sessions.delete_session(session)
    end
  end
end
