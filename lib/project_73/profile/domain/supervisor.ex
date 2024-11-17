defmodule Project73.Profile.Domain.Supervisor do
  use Horde.DynamicSupervisor

  def start_link(args) do
    Horde.DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Horde.DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_actor(profile_id) do
    case Horde.Registry.lookup(:profile_registry, profile_id) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        case Horde.DynamicSupervisor.start_child(
               __MODULE__,
               {Project73.Profile.Domain.Actor, profile_id}
             ) do
          {:ok, pid} ->
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            {:ok, pid}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end
end
