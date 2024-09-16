defmodule Project73.Profile.Event.Created do
  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          username: String.t(),
          email: String.t(),
          timestamp: DateTime.t(),
          sequence_number: integer()
        }

  defstruct [
    :id,
    :provider,
    :username,
    :email,
    :timestamp,
    :sequence_number
  ]
end

defmodule Project73.Profile.Event.UsernameChanged do
  @type t :: %__MODULE__{
          username: String.t(),
          timestamp: DateTime.t(),
          sequence_number: integer()
        }

  defstruct [
    :id,
    :username,
    :timestamp,
    :sequence_number
  ]
end

defmodule Project73.Profile.Aggregate do
  alias Project73.Profile.Event

  @type event ::
          {:profile_created, Event.Created.t()}
          | {:profile_updated, Event.UsernameChanged.t()}

  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          email: String.t(),
          username: String.t(),
          created_at: DateTime.t(),
          version: integer()
        }

  defstruct [
    :id,
    :provider,
    :email,
    :username,
    :created_at,
    :version
  ]

  def provider_id(provider, id) do
    "#{provider}:#{id}"
  end

  def empty() do
    %__MODULE__{}
  end

  @spec create(t(), String.t(), String.t(), String.t()) ::
          {:ok, [event()]} | {:error, :already_created}
  def create(%__MODULE__{} = self, id, provider, email) do
    case self.created_at do
      nil ->
        {:ok,
         [
           {:profile_created,
            %Event.Created{
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

  @type update_profile_data :: %{:username => String.t()}

  @spec update_profile(t(), update_profile_data()) :: [event()]
  def update_profile(%__MODULE__{} = self, data) do
    [
      {:profile_updated,
       %Event.UsernameChanged{
         username: data.username,
         timestamp: DateTime.utc_now(),
         sequence_number: self.version + 1
       }}
    ]
  end

  @spec apply(t(), [event()]) :: t()
  def apply(self, events) do
    Enum.reduce(events, self, &apply_event(&2, &1))
  end

  defp apply_event(%__MODULE__{} = _self, {:profile_created, event}) do
    %__MODULE__{
      id: event.id,
      provider: event.provider,
      email: event.email,
      created_at: event.timestamp,
      version: event.sequence_number
    }
  end

  defp apply_event(%__MODULE__{} = self, {:profile_updated, event}) do
    %__MODULE__{
      self
      | username: event.username,
        version: event.sequence_number
    }
  end
end
