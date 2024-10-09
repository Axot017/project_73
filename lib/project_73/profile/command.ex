defmodule Project73.Profile.Command do
  alias Project73.Profile.Command

  @type t() ::
          Command.Create.t()
          | Command.CreatePaymentAccount.t()
          | Command.RequestDeposit.t()
          | Command.UpdateProfile.t()

  defmodule Create do
    @type t() :: %__MODULE__{
            id: String.t(),
            provider: String.t(),
            email: String.t()
          }
    defstruct [:id, :provider, :email]
  end

  defmodule CreatePaymentAccount do
    @type t() :: %__MODULE__{}
    defstruct []
  end

  defmodule RequestDeposit do
    @type t() :: %__MODULE__{
            amount: Decimal.t()
          }
    defstruct [:amount]
  end

  defmodule UpdateProfile do
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
