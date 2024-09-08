defmodule Project73.Auction.Notifier do
  @callback auction_updated(auction_id :: String.t(), auction :: any()) :: any()
end
