defmodule Project73.Profile.StripeConnector do
  @behaviour Project73.Profile.PaymentProvider
  require Logger

  def create_customer(%{email: email, username: username, address: address, id: id}) do
    with {:ok, customer} <-
           Stripe.Customer.create(%{
             email: email,
             name: username,
             address: address,
             metadata: %{
               "id" => id
             }
           }) do
      Logger.debug("Customer created with id #{customer.id} created for user: #{id}")
      {:ok, customer.id}
    else
      {:error, error} ->
        Logger.error("Customer creation failed: #{inspect(error)}")
        {:error, error}
    end
  end

  def create_payment_intent(%{
        amount: amount,
        customer_id: customer_id,
        user_id: user_id
      }) do
    with {:ok, payment_intent} <-
           Stripe.PaymentIntent.create(%{
             amount: amount,
             currency: "PLN",
             customer: customer_id,
             metadata: %{
               "id" => user_id
             }
           }) do
      Logger.debug("Payment intent created for user: #{user_id}")
      {:ok, payment_intent}
    else
      {:error, error} ->
        Logger.error("Payment intent creation failed: #{inspect(error)}")
        {:error, error}
    end
  end
end
