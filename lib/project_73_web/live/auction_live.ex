defmodule Project73Web.AuctionLive do
  require Logger
  alias Phoenix.PubSub
  alias Project73.Auction
  use Project73Web, :live_view

  def mount(_params, session, socket) do
    Logger.info("Session: #{inspect(session)}")
    PubSub.subscribe(Project73.PubSub, "auction:test_auction")
    {:ok, pid} = Auction.Supervisor.actor_pid("test_auction")

    auction = Auction.Actor.get(pid)
    Logger.info("Auction: #{inspect(auction)}")

    {:ok, assign(socket, auction: auction)}
  end

  def handle_info({:new_bid, amount}, socket) do
    auction = socket.assigns.auction
    {:noreply, assign(socket, auction: %{auction | current_price: amount})}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Current Auction</h1>
      <%= if @auction != nil and @auction.name !== nil do %>
        <p>Name: <%= @auction.name %></p>
        <p>Current Price: <%= @auction.current_price %></p>
        <button phx-click="bid">Bid $10</button>
      <% else %>
        <button phx-click="create_auction">Create Auction</button>
      <% end %>

      <.link href={~p"/auth/google"}>Login</.link>
    </div>
    """
  end

  def handle_event("create_auction", _params, socket) do
    {:ok, pid} = Auction.Supervisor.actor_pid("test_auction")
    :ok = Auction.Actor.create(pid, "Test Auction", 100)
    auction = Auction.Actor.get(pid)

    {:noreply, assign(socket, auction: auction)}
  end

  def handle_event("bid", _params, socket) do
    {:ok, pid} = Auction.Supervisor.actor_pid("test_auction")
    price = socket.assigns.auction.current_price + 10
    :ok = Auction.Actor.bid(pid, "Test Bidder", price)

    {:noreply, socket}
  end
end
