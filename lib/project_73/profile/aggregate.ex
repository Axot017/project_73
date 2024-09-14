defmodule Project73.Profile.Event.Created do
  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          email: String.t(),
          timestamp: DateTime.t(),
          sequence_number: integer()
        }

  defstruct [
    :id,
    :provider,
    :email,
    :timestamp,
    :sequence_number
  ]
end

defmodule Project73.Profile.Aggregate do
  alias Project73.Profile.Event

  @type event :: {:profile_created, Event.Created.t()}

  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          email: String.t(),
          created_at: DateTime.t()
        }

  defstruct [
    :id,
    :provider,
    :email,
    :created_at
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

  @spec apply(t(), [event()]) :: t()
  def apply(self, events) do
    Enum.reduce(events, self, &apply_event(&2, &1))
  end

  defp apply_event(%__MODULE__{} = _self, {:profile_created, event}) do
    %__MODULE__{
      id: event.id,
      provider: event.provider,
      email: event.email,
      created_at: event.timestamp
    }
  end
end
