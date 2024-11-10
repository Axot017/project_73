defmodule Project73.Profile.StripeConnector do
  @behaviour Project73.Profile.PaymentProvider
  alias Project73.Utils.Json
  require Logger

  def create_customer(%{email: email, username: username, address: address, id: id}) do
    request =
      %{
        email: email,
        name: username,
        address: address,
        metadata: %{
          "id" => id
        }
      }
      |> Json.serialize(&Json.to_map/1)

    Logger.debug("Creating customer for user: #{id} with request: #{inspect(request)}")

    with {:ok, customer} <-
           Stripe.Customer.create(request) do
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
    request =
      %{
        amount: amount,
        currency: "PLN",
        customer: customer_id,
        automatic_payment_methods: %{
          enabled: true
        },
        metadata: %{
          "id" => user_id
        }
      }
      |> Json.serialize(&Json.to_map/1)

    with {:ok, payment_intent} <-
           Stripe.PaymentIntent.create(request) do
      Logger.debug("Payment intent created for user: #{user_id}")
      {:ok, payment_intent}
    else
      {:error, error} ->
        Logger.error("Payment intent creation failed: #{inspect(error)}")
        {:error, error}
    end
  end
end
