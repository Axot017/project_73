defmodule Project73.Auction.AggregateTest do
  use ExUnit.Case
  alias Project73.Auction.Aggregate

  describe "create/3" do
    test "creates an auction when it is not already created" do
      auction = Aggregate.new("auction_id")

      {:ok, events} = Aggregate.create(auction, "Test Auction", 100)

      assert [%{type: :auction_created, name: "Test Auction", initial_price: 100}] = events
    end

    test "returns an error if auction is already created" do
      auction = Aggregate.new("auction_id")
      {:ok, events} = Aggregate.create(auction, "Test Auction", 100)

      # Apply the event to the aggregate
      auction = Aggregate.apply(auction, events)

      # Try creating again
      assert {:error, :already_created} = Aggregate.create(auction, "Another Auction", 200)
    end
  end
end
