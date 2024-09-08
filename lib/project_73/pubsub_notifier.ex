defmodule Project73.PubsubNotifier do
  alias Phoenix.PubSub
  @behaviour Project73.Auction.Notifier

  def auction_updated(auction_id, event) do
    PubSub.broadcast(Project73.PubSub, "auction:#{auction_id}", event)
  end
end
