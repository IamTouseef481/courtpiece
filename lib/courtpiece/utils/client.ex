defmodule CourtPieceWeb.Utils.Client do
  @moduledoc """
    This module implements HTTPoison
  """
  use HTTPoison.Base

  def request_url(:get, url, headers) do
    case get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}} when code in 200..299 ->
        {:ok, body}

      {:ok, %HTTPoison.Response{body: {:error, reason}}} ->
        {:error, reason}

      {:ok, %HTTPoison.Response{body: {:ok, %{"error" => reason}}}} ->
        {:error, "Api Error: #{reason}"}

      {:ok,
       %HTTPoison.Response{body: %{"error" => %{"code" => _code, "message" => "Invalid OAuth access token data."}}}} ->
        {:error, :invalid_o_auth}

      {:ok, %HTTPoison.Response{body: %{"error" => %{"code" => _code, "message" => _message}}}} ->
        {:error, :invalid_o_auth}

      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, "Returned response not in 200. #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Api Error: #{reason}"}
    end
  end

  def request_url(:post, url, headers, body \\ %{}) do
    case post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: code, body: %{"access_token" => a_token}}} when code in 200..299 ->
        {:ok, %{"access_token" => a_token}}

      {:ok, %HTTPoison.Response{body: %{"error" => reason}}} ->
        reason =
          case reason do
            "invalid_grant" -> :invalid_grant
            x -> x
          end

        {:error, reason}

      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, "Returned response not in 200. #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Api Error: #{reason}"}
    end
  end

  def process_response_body(body) do
    cond do
      body |> String.match?(~r|access denied|i) ->
        {:error, "Access denied. You may not have permission to view this resource."}

      body == "Internal Server Error" ->
        {:error, "Internal Server Error"}

      true ->
        Jason.decode!(body)
    end
  end

  def process_request_body(body) when is_binary(body), do: body

  def process_request_body(body) do
    body
    |> Jason.encode!()
  end
end
