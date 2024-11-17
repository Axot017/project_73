defmodule Project73.Profile.Domain.Event do
  alias Project73.Profile.Domain.Event

  @type t ::
          Event.Created.t()
          | Event.FirstNameChanged.t()
          | Event.LastNameChanged.t()
          | Event.AddressChanged.t()
          | Event.UsernameChanged.t()

  defmodule Created do
    @type t() :: %__MODULE__{
            id: String.t(),
            provider: String.t(),
            email: String.t(),
            timestamp: DateTime.t(),
            sequence_number: integer()
          }

    defstruct [:id, :provider, :email, :timestamp, :sequence_number]
  end

  defmodule FirstNameChanged do
    @type t() :: %__MODULE__{
            first_name: String.t(),
            timestamp: DateTime.t(),
            sequence_number: integer()
          }
    defstruct [:first_name, :timestamp, :sequence_number]
  end

  defmodule LastNameChanged do
    @type t() :: %__MODULE__{
            last_name: String.t(),
            timestamp: DateTime.t(),
            sequence_number: integer()
          }
    defstruct [:last_name, :timestamp, :sequence_number]
  end

  defmodule AddressChanged do
    alias Project73.Shared.Address

    @type t() :: %__MODULE__{
            address: Address.t(),
            timestamp: DateTime.t(),
            sequence_number: integer()
          }
    defstruct [:address, :timestamp, :sequence_number]
  end

  defmodule UsernameChanged do
    @type t() :: %__MODULE__{
            username: String.t(),
            timestamp: DateTime.t(),
            sequence_number: integer()
          }
    defstruct [:username, :timestamp, :sequence_number]
  end

  defmodule PaymentAccountUpdated do
    @type t() :: %__MODULE__{
            payment_account_id: String.t(),
            timestamp: DateTime.t(),
            sequence_number: integer()
          }
    defstruct [:payment_account_id, :timestamp, :sequence_number]
  end
end
