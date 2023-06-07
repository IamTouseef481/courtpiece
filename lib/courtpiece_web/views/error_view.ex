defmodule CourtPieceWeb.ErrorView do
  use CourtPieceWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  def render("500.json", _assigns) do
    %{error: %{detail: "Internal Server Error"}}
  end

  def render("404.json", _assigns) do
    %{error: %{detail: "Not Found"}}
  end

  def render("403.json", _assigns) do
    %{error: %{detail: "Unauthorized"}}
  end

  def render("401.json", _assigns) do
    %{error: %{detail: "Unauthorized"}}
  end

  def render("501.json", %{error: error}) do
    %{error: %{detail: error}}
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{error: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
