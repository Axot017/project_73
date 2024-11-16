defmodule Project73Web.HomeLive do
  require Logger
  use Project73Web, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
