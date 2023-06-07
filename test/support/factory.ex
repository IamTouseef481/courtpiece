defmodule CourtPiece.Factory do
  @moduledoc """
    This module defines factories for test cases
  """
  use ExMachina.Ecto, repo: CourtPiece.Repo
  alias CourtPiece.Games.{Game, GameTable}
  alias CourtPiece.Accounts.{Session, SocialAuth, User}
  alias CourtPiece.Players.Profile

  def user_factory(params \\ %{}) do
    %User{
      name: params[:name] || sequence("admin"),
      email: params[:email] || sequence("admin") <> "@admin.com",
      user_role: params[:user_role] || Enum.random(["social", "guest"])
    }
  end

  def game_table_factory(params \\ %{}) do
    %GameTable{
      bet_value: params[:bet_value] || sequence("500"),
      game_id: params[:game_id] || sequence("50b3cc1a-2382-4cdb-a80a-7abc7553137a")
    }
  end

  def game_factory(params \\ %{}) do
    %Game{
      name: params[:name] || sequence("test"),
      title: params[:title] || sequence("hidden sir")
    }
  end

  def social_auth_factory(params \\ %{}) do
    %SocialAuth{
      long_token: params[:long_token] || Faker.Lorem.characters(10) |> to_string,
      user_id: params[:user_id] || Ecto.UUID.generate(),
      login_type: params[:login_type] || Enum.random(~w(facebook google))
    }
  end

  def session_factory(params \\ %{}) do
    %Session{
      user_id: params[:user_id] || Ecto.UUID.generate(),
      token: params[:token] || Faker.Lorem.characters(10) |> to_string,
      device_id: params[:device_id] || sequence(gen_random_text())
    }
  end

  def profile_factory(params \\ %{}) do
    %Profile{
      image_url: sequence(gen_random_text()),
      level: params[:level] || String.to_integer(sequence("0")),
      total_coins: params[:total_coins] || String.to_integer(sequence("100")),
      user_id: params[:user_id] || Ecto.UUID.generate()
    }
  end

  def gen_random_text do
    for _str <- 1..5, into: "", do: <<Enum.random(?a..?z)>>
  end
end
