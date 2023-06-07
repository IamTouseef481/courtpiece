defmodule CourtPiece.GamesTest do
  use CourtPiece.DataCase, async: true

  alias CourtPiece.Factory
  alias CourtPiece.Games
  alias CourtPiece.Games.Game
  import CourtPiece.GamesFixture

  setup do
    valid_attrs = %{bet_value: "500", game_id: "50b3cc1a-2382-4cdb-a80a-7abc7553137a"}
    invalid_attrs = %{}

    {:ok, valid_attrs: valid_attrs, invalid_attrs: invalid_attrs}
  end

  describe "get_game_table_by/1" do
    test "get_game_table_by/1 returns bet value by game id", context do
      game = game_fixture(%{name: "test", title: "Hidden Sir"})

      game_table_attr = Map.put(context.valid_attrs, :game_id, game.id)

      %{bet_value: bet_value} = game_table_fixture(game_table_attr)
      assert Games.get_game_table_by(game.id) == [bet_value]
    end
  end

  describe "create_game/1" do
    test "create_game/1 rcreate a new game", context do
      game = game_fixture(%{name: "test", title: "Hidden Sir"})

      params = Factory.game_factory() |> Map.from_struct()
      assert {:ok, %Games.Game{}} = Games.create_game(params)
    end
  end
end
