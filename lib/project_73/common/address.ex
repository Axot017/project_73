defmodule Project73.Common.Address do
  @type t :: %__MODULE__{
          country: String.t(),
          city: String.t(),
          postal_code: String.t(),
          line1: String.t(),
          line2: String.t()
        }

  defstruct [
    :country,
    :city,
    :postal_code,
    :line1,
    :line2
  ]
end
