defmodule Project73.Profile.PaymentProvider do
  @callback create_customer(term()) :: {:ok, String.t()} | {:error, term()}
end
