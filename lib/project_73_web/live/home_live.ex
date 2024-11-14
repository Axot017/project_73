defmodule Project73Web.HomeLive do
  require Logger
  use Project73Web, :live_view

  def mount(_params, session, socket) do
    {:ok, socket |> assign(current_user: session["current_user"])}
  end

  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
