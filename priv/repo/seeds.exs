# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CourtPiece.Repo.insert!(%CourtPiece.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
# l_token = "GGQVlieVU3MXpzTVNZAVFpKSVZAOOTdpTGFnZAUJoSnJ3TWlaZAVlPWFVadzZAEa2hsN0FsMGxPLVl2OUdqV2hvNWRBd3pjVTd2aWl2N245cmlxT3NfX1REaGQ4ODZAYUjliRzgxWVAyY0NwdGJrRlV5SVBYaTBvZAFRzOVZAYU0ZAlSXNYWk1fUQZDZD"
# {:ok, user} = CourtPiece.Repo.insert(%CourtPiece.Accounts.User{email: "attufhabib@yahoo.com", name: "Attaf"})
# s_data = %CourtPiece.Accounts.SocialAuth{login_type: :facebook, long_token: l_token, user_id: user.id}
# {:ok, s_auth} = CourtPiece.Repo.insert(s_data)

{:ok, game1} =
  CourtPiece.Games.Game.changeset(%CourtPiece.Games.Game{}, %{name: "single", title: "Single Sir"})
  |> CourtPiece.Repo.insert()

{:ok, game2} =
  CourtPiece.Games.Game.changeset(%CourtPiece.Games.Game{}, %{name: "double", title: "Double Sir"})
  |> CourtPiece.Repo.insert()

{:ok, game3} =
  CourtPiece.Games.Game.changeset(%CourtPiece.Games.Game{}, %{name: "ace", title: "Ace Sir"})
  |> CourtPiece.Repo.insert()

{:ok, game4} =
  CourtPiece.Games.Game.changeset(%CourtPiece.Games.Game{}, %{name: "hidden", title: "Hidden Sir"})
  |> CourtPiece.Repo.insert()

Enum.map([game1, game2, game3, game4], fn game ->
  Enum.map([500, 1500, 5000, 25000], fn x ->
    CourtPiece.Games.GameTable.changeset(%CourtPiece.Games.GameTable{}, %{bet_value: x, game_id: game.id})
    |> CourtPiece.Repo.insert()
  end)
end)
