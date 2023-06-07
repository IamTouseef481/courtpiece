defmodule CourtPiece.Utils.ApiHelper do
  @moduledoc """
    This module defines helping functions for generating Api Response
  """

  def response(msg \\ "", data \\ [], status \\ 200) do
    %{message: msg, data: data, status: status}
  end
end
