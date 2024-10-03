defmodule Project73Web.WalletLive do
  require Logger
  alias Project73.Profile
  use Project73Web, :live_view

  def mount(_params, %{"current_user" => profile}, socket) do
    Logger.debug("Profile loaded: #{inspect(profile)}")
    {:ok, pid} = Profile.Supervisor.get_actor(profile.id)

    {:ok,
     socket
     |> assign(
       profile: profile,
       actor_pid: pid
     )}
  end

  def handle_event("deposit", _params, socket) do
    pid = socket.assigns.actor_pid
    {:ok, deposit_data} = Profile.Actor.request_deposit(pid, Decimal.new("1000.00"))
    Logger.debug("Deposit data: #{inspect(deposit_data)}")

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= Decimal.to_string(@profile.wallet_balance) %>
    </div>
    <.button phx-click="deposit">Deposit</.button>
    """
  end
end
