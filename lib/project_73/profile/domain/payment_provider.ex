defmodule Project73.Profile.Domain.PaymentProvider do
  @callback create_customer(term()) :: {:ok, String.t()} | {:error, term()}

  @callback create_payment_intent(term()) :: {:ok, term()} | {:error, term()}
end
