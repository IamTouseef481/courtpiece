defmodule CourtPieceWeb.CommonParameters do
  @moduledoc "Common parameter declarations for phoenix swagger"
  #  alias PhoenixSwagger.Path.PathObject
  alias PhoenixSwagger.Schema
  #  import PhoenixSwagger.Path

  def authorization_props(%Schema{} = schema) do
    schema
    |> Schema.property(:device_id, :string, "The device_id from where user is logging", required: true)
  end
end
