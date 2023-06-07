defmodule CourtPiece.Token do
  @signing_salt "z00Ojcov4yRpFLYvY7vHSfQVzkM9tssXCf7Q4dscUPVBc4NFARTLvjfzNNvUgCvP"
  @moduledoc false

  @doc """
  Create token for given data
  """
  @spec sign(map()) :: {:ok, nonempty_binary()}
  def sign(data) do
    token = Phoenix.Token.sign(CourtPieceWeb.Endpoint, @signing_salt, data, max_age: :infinity)
    {:ok, token}
  end

  @doc """
  Verify given token by:
  - Verify token signature
  - Verify expiration time
  """
  @spec verify(String.t()) :: {:ok, any()} | {:error, :unauthenticated}
  def verify(token) do
    case Phoenix.Token.verify(CourtPieceWeb.Endpoint, @signing_salt, token) do
      {:ok, data} -> {:ok, data}
      _error -> {:error, :unauthenticated}
    end
  end
end
