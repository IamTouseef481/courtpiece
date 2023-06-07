defmodule CourtPieceWeb.Utils.CommonFunctions do
  @moduledoc """
    This module implements common util functions using in app
  """
  def keyword_list_to_list_of_maps(args, :string_keys) when is_list(args) do
    Enum.map(args, fn {k, v} -> Map.put(%{}, to_string(k), v) end)
  end

  def keyword_list_to_list_of_maps(args) when is_list(args) do
    Enum.map(args, fn {k, v} -> Map.put(%{}, k, v) end)
  end
end
