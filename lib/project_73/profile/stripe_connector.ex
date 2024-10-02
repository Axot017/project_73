defmodule Project73.Profile.StripeConnector do
  @behaviour Project73.Profile.PaymentProvider

  def create_customer(user_data) do
    with {:ok, customer} <-
           Stripe.Customer.create(%{
             email: user_data.email,
             name: user_data.username,
             address: user_data.address,
             metadata: %{
               "id" => user_data.id
             }
           }) do
      {:ok, customer.id}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def create_payment_intent(payment_data) do
    with {:ok, payment_intent} <-
           Stripe.PaymentIntent.create(%{
             amount: payment_data.amount,
             currency: "PLN",
             customer: payment_data.customer_id,
             metadata: %{
               "id" => payment_data.user_id
             }
           }) do
      {:ok, payment_intent}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
