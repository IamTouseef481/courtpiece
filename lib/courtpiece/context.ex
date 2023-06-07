defmodule CourtPiece.Context do
  @moduledoc """
  This module defines the generic functions for schemas
  """

  import Ecto.Query, warn: false

  @spec change(atom(), struct(), map()) :: Ecto.Changeset.t()
  def change(model, data, attrs \\ %{}) do
    model.changeset(data, attrs)
  end
end
