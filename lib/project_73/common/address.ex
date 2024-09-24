defmodule Project73.Common.Address do
  @type t :: %{
          country: String.t(),
          city: String.t(),
          postal_code: String.t(),
          line1: String.t(),
          line2: String.t()
        }
end
