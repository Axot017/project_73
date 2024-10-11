defmodule Project73.Profile.Command do
  alias Project73.Profile.Command

  @type t() ::
          Command.Create.t()
          | Command.CreatePaymentAccount.t()
          | Command.RequestDeposit.t()
          | Command.Update.t()

  defmodule Create do
    @type t() :: %__MODULE__{
            id: String.t(),
            provider: String.t(),
            email: String.t()
          }
    defstruct [:id, :provider, :email]
  end

  defmodule UpdatePaymentAccount do
    @type t() :: %__MODULE__{
            payment_account_id: String.t()
          }
    defstruct [:payment_account_id]
  end

  defmodule RequestDeposit do
    @type t() :: %__MODULE__{
            amount: Decimal.t()
          }
    defstruct [:amount]
  end

  defmodule Update do
    alias Project73.Shared.Address

    @type t() :: %__MODULE__{
            username: String.t(),
            first_name: String.t(),
            last_name: String.t(),
            address: Address.t()
          }
    defstruct [
      :username,
      :first_name,
      :last_name,
      :address
    ]
  end
end
