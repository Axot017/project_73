defmodule Project73.Profile.Aggregate do
  require Logger
  alias Project73.Profile.Event
  alias Project73.Profile.Command

  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          email: String.t(),
          username: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          address: Project73.Shared.Address.t(),
          avatar_url: String.t(),
          payment_account_id: String.t(),
          wallet_balance: Decimal.t(),
          created_at: DateTime.t(),
          version: integer()
        }

  defstruct [
    :id,
    :provider,
    :email,
    :username,
    :first_name,
    :last_name,
    :address,
    :avatar_url,
    :payment_account_id,
    :wallet_balance,
    :created_at,
    :version
  ]

  def provider_id(provider, id) do
    "#{provider}:#{id}"
  end

  def empty() do
    %__MODULE__{}
  end

  def handle_command(%__MODULE__{} = self, cmd) do
    case Command.validate(cmd) do
      {:ok, cmd} ->
        handle_valid_command(self, cmd)

      {:error, errors} ->
        Logger.info("Invalid command: #{inspect(errors)}")
        {:error, {:validation, errors}}
    end
  end

  defp handle_valid_command(%__MODULE__{} = self, %Command.Create{} = cmd) do
    case self.created_at do
      nil ->
        {:ok,
         [
           %Event.Created{
             id: cmd.id,
             provider: cmd.provider,
             email: cmd.email,
             timestamp: DateTime.utc_now(),
             sequence_number: 1
           }
         ]}

      _ ->
        {:error, :already_created}
    end
  end

  defp handle_valid_command(%__MODULE__{} = self, %Command.UpdatePaymentAccount{} = cmd) do
    if self.payment_account_id == nil do
      {:ok,
       [
         %Event.PaymentAccountUpdated{
           payment_account_id: cmd.payment_account_id,
           timestamp: DateTime.utc_now(),
           sequence_number: self.version + 1
         }
       ]}
    else
      {:error, :already_created}
    end
  end

  defp handle_valid_command(%__MODULE__{} = self, %Command.Update{} = cmd) do
    events =
      change_username(self, cmd.username) ++
        change_first_name(self, cmd.first_name) ++
        change_last_name(self, cmd.last_name) ++
        change_address(self, cmd.address)

    versioned_events =
      events
      |> Enum.with_index(self.version + 1)
      |> Enum.map(fn {event, index} ->
        Map.put(event, :sequence_number, index)
      end)

    {:ok, versioned_events}
  end

  defp change_username(%__MODULE__{} = self, username) do
    case self.username == username do
      true ->
        []

      false ->
        [
          %Event.UsernameChanged{
            username: username,
            timestamp: DateTime.utc_now(),
            sequence_number: self.version + 1
          }
        ]
    end
  end

  defp change_first_name(%__MODULE__{} = self, first_name) do
    case self.first_name == first_name do
      true ->
        []

      false ->
        [
          %Event.FirstNameChanged{
            first_name: first_name,
            timestamp: DateTime.utc_now(),
            sequence_number: self.version + 1
          }
        ]
    end
  end

  defp change_last_name(%__MODULE__{} = self, last_name) do
    case self.last_name == last_name do
      true ->
        []

      false ->
        [
          %Event.LastNameChanged{
            last_name: last_name,
            timestamp: DateTime.utc_now(),
            sequence_number: self.version + 1
          }
        ]
    end
  end

  defp change_address(%__MODULE__{} = self, address) do
    case self.address == address do
      true ->
        []

      false ->
        [
          %Event.AddressChanged{
            address: address,
            timestamp: DateTime.utc_now(),
            sequence_number: self.version + 1
          }
        ]
    end
  end

  def needs_setup(%__MODULE__{} = self) do
    self.username == nil || self.first_name == nil || self.last_name == nil || self.address == nil
  end

  def needs_payment_account(%__MODULE__{} = self) do
    self.payment_account_id == nil
  end

  def apply(self, events) do
    Enum.reduce(events, self, &apply_event(&2, &1))
  end

  defp apply_event(%__MODULE__{} = _self, %Event.Created{} = event) do
    %__MODULE__{
      id: event.id,
      provider: event.provider,
      email: event.email,
      avatar_url: nil,
      created_at: event.timestamp,
      wallet_balance: Decimal.new(0),
      version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, %Event.UsernameChanged{} = event) do
    %__MODULE__{
      self
      | username: event.username,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, %Event.FirstNameChanged{} = event) do
    %__MODULE__{
      self
      | first_name: event.first_name,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, %Event.LastNameChanged{} = event) do
    %__MODULE__{
      self
      | last_name: event.last_name,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, %Event.AddressChanged{} = event) do
    %__MODULE__{
      self
      | address: event.address,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, %Event.PaymentAccountUpdated{} = event) do
    %__MODULE__{
      self
      | payment_account_id: event.payment_account_id,
        version: event.sequence_number
    }
  end
end
