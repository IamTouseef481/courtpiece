defmodule CourtPiece.SocialHelpers do
  @moduledoc """
  This module defines the functions to authenticate the social credentials
  """

  alias CourtPieceWeb.Utils.Client

  @fb_api %{
    token_url: "https://graph.facebook.com/v15.0/oauth/access_token?grant_type=fb_exchange_token",
    #    data_url: "https://graph.fb.gg/me?fields=name,email,picture&type=square",
    data_url: "https://graph.facebook.com/v15.0/me?fields=name,email,picture&type=square",
    client_id: "1336649196886349",
    client_secret: "6f428021b0d1285d7c999e59e9e30fa8"
  }
  @google_api %{
    data_url: "https://www.googleapis.com/oauth2/v2/userinfo",
    client_id: "177793665332-c70drujkhlhc0eauar4n3k69rc9tf4oe.apps.googleusercontent.com",
    client_secret: "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",
    redirect_uri: "https://developers.google.com/oauthplayground",
    grant_type: "authorization_code",
    content_type: "application/x-www-form-urlencoded"
  }

  @fb_fetch_friends_api "https://graph.facebook.com/v15.0/me?fields=friends{name,id,picture}"

  @doc """
  Get long token for given token
  """
  @spec get_long_token(String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def get_long_token(short_token, "facebook" = social_type) do
    api_url = build_token_url(social_type, Map.put(@fb_api, :short_token, short_token))

    Client.request_url(:get, api_url, [])
  end

  def get_long_token(short_token, _) do
    {:ok, %{"access_token" => short_token}}
  end

  @doc """
  Get user data from token
  """
  @spec get_user_data(String.t(), String.t()) :: {:ok, map()} | {:error, reason :: any()}
  def get_user_data(long_token, "facebook") do
    api_url = @fb_api[:data_url]
    headers = [{"Authorization", "Bearer #{long_token}"}]

    case Client.request_url(:get, api_url, headers) do
      {:ok, %{"picture" => %{"data" => %{"url" => url}}} = social_data} ->
        {:ok, Map.put(social_data, "picture", url)}

      x ->
        x
    end
  end

  def get_user_data(token, "google") do
    api_url = @google_api[:data_url]
    headers = [{"Authorization", "Bearer #{token}"}]

    Client.request_url(:get, api_url, headers)
  end

  defp build_token_url("facebook", params) do
    @fb_api[:token_url] <>
      "&client_id=#{params[:client_id]}&client_secret=#{params[:client_secret]}&fb_exchange_token=#{params[:short_token]}"
  end

  @doc """
  Get user Friends
  """
  @spec get_user_friends(String.t(), String.t()) :: {:ok, map()} | {:error, reason :: any()}
  def get_user_friends(long_token, "facebook") do
    headers = [{"Authorization", "Bearer #{long_token}"}]

    case Client.request_url(:get, @fb_fetch_friends_api, headers) do
      {:ok, %{"friends" => %{"data" => friends}}} ->
        friends

      x ->
        x
    end
  end

  def get_user_friends(_, _), do: []
end
