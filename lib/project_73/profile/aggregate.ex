defmodule Project73.Profile.Aggregate do
  alias Project73.Utils.Validator

  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          email: String.t(),
          username: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          address: Project73.Common.Address.t(),
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

  defp create_command_validator(),
    do:
      Validator.new()
      |> Validator.field(:id, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:provider, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:email, [&Validator.string/1, &Validator.is_not_empty/1])

  def create(%__MODULE__{} = self, data) do
    case Validator.apply(create_command_validator(), data) do
      {:ok,
       %{
         id: id,
         provider: provider,
         email: email
       }} ->
        create(self, id, provider, email)

      error ->
        error
    end
  end

  defp create(%__MODULE__{} = self, id, provider, email) do
    case self.created_at do
      nil ->
        {:ok,
         [
           {:profile_created,
            %{
              id: id,
              provider: provider,
              email: email,
              timestamp: DateTime.utc_now(),
              sequence_number: 1
            }}
         ]}

      _ ->
        {:error, :already_created}
    end
  end

  defp update_command_validator(),
    do:
      Validator.new()
      |> Validator.field(:username, [&Validator.string/1, Validator.min_size(3)])
      |> Validator.field(:first_name, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:last_name, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:country, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:city, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:postal_code, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:address_line1, [&Validator.string/1, &Validator.is_not_empty/1])
      |> Validator.field(:address_line2, [&Validator.string/1])

  def update_profile(%__MODULE__{} = self, data) do
    with {:ok,
          %{
            username: username,
            first_name: first_name,
            last_name: last_name,
            country: country,
            city: city,
            postal_code: postal_code,
            address_line1: address_line1,
            address_line2: address_line2
          }} <- Validator.apply(update_command_validator(), data) do
      events =
        []
        |> add_event_if_changed(self, :username, username, :username_changed)
        |> add_event_if_changed(self, :first_name, first_name, :first_name_changed)
        |> add_event_if_changed(self, :last_name, last_name, :last_name_changed)
        |> add_address_changed_event(self, %{
          country: country,
          city: city,
          postal_code: postal_code,
          line1: address_line1,
          line2: address_line2
        })

      if events == [] do
        {:ok, []}
      else
        versioned_events =
          events
          |> Enum.with_index(&{&2 + self.version + 1, &1})
          |> Enum.map(fn {index, {event, payload}} ->
            {event, Map.put(payload, :sequence_number, index)}
          end)

        {:ok, versioned_events}
      end
    else
      error ->
        error
    end
  end

  def update_payment_account(%__MODULE__{} = self, payment_account_id) do
    if self.payment_account_id == payment_account_id do
      {:ok, []}
    else
      {:ok,
       [
         {:payment_account_updated,
          %{
            payment_account_id: payment_account_id,
            timestamp: DateTime.utc_now(),
            sequence_number: self.version + 1
          }}
       ]}
    end
  end

  defp add_event_if_changed(events, self, field, new_value, event_type) do
    if Map.get(self, field) != new_value do
      [{event_type, %{field => new_value, timestamp: DateTime.utc_now()}} | events]
    else
      events
    end
  end

  defp add_address_changed_event(events, self, new_address) do
    current_address = Map.get(self, :address, %{})

    if current_address !== new_address do
      [
        {:address_changed, %{address: new_address, timestamp: DateTime.utc_now()}}
        | events
      ]
    else
      events
    end
  end

  def apply(self, events) do
    Enum.reduce(events, self, &apply_event(&2, &1))
  end

  defp apply_event(%__MODULE__{} = _self, {:profile_created, event}) do
    %__MODULE__{
      id: event.id,
      provider: event.provider,
      email: event.email,
      avatar_url: nil,
      created_at: event.timestamp,
      version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, {:username_changed, event}) do
    %__MODULE__{
      self
      | username: event.username,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, {:first_name_changed, event}) do
    %__MODULE__{
      self
      | first_name: event.first_name,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, {:last_name_changed, event}) do
    %__MODULE__{
      self
      | last_name: event.last_name,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, {:address_changed, event}) do
    %__MODULE__{
      self
      | address: event.address,
        version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, {:payment_account_updated, event}) do
    %__MODULE__{
      self
      | payment_account_id: event.payment_account_id,
        version: event.sequence_number
    }
  end
end
