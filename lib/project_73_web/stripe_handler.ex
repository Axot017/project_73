defmodule Project73Web.StripeHandler do
  require Logger

  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{type: "payment_intent.created"} = event) do
    Logger.info("Payment intent created: #{inspect(event)}")
    :ok
  end

  @impl true
  def handle_event(event) do
    Logger.warning("Unhandled event: #{inspect(event)}")
    :ok
  end
end
