defmodule Project73Web.NewAuctionLive do
  require Logger
  use Project73Web, :live_view

  def mount(_params, session, socket) do
    {:ok, assign(socket, current_user: session["current_user"])}
  end

  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
