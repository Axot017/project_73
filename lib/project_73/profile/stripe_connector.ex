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
end
