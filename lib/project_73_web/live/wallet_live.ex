defmodule Project73Web.WalletLive do
  require Logger
  alias Project73.Profile
  use Project73Web, :live_view

  @stripe_public_key System.get_env("STRIPE_PUBLISHABLE_KEY")

  def mount(_params, %{"current_user" => profile}, socket) do
    Logger.debug("Profile loaded: #{inspect(profile)}")
    {:ok, pid} = Profile.Supervisor.get_actor(profile.id)

    {:ok,
     socket
     |> assign(
       current_user: profile,
       actor_pid: pid,
       stripe_public_key: @stripe_public_key
     )}
  end

  def handle_event("deposit", _params, socket) do
    pid = socket.assigns.actor_pid
    {:ok, deposit_data} = Profile.Actor.request_deposit(pid, Decimal.new("1000.00"))
    Logger.debug("Deposit data: #{inspect(deposit_data)}")

    {:noreply,
     socket
     |> push_event("start_deposit", %{client_secret: deposit_data.client_secret})}
  end

  def render(assigns) do
    ~H"""
    <script>
      window.addEventListener("phx:start_deposit", (event) => {
        console.log("phx:start_deposit", event.detail);
        const stripe = Stripe("<%= @stripe_public_key %>");
        const clientSecret = event.detail.client_secret;
        
        stripe.confirmPayment({
          clientSecret: clientSecret,
          confirmParams: {
            return_url: "http://localhost:4000",
          }
        }).then((result) => {
            console.log(result);
        });
      });
    </script>
    <div>
      <%= Decimal.to_string(@current_user.wallet_balance) %>
    </div>
    <.modal id="test-modal" show={true}>
      Test modal
    </.modal>
    <.button phx-click="deposit">Deposit</.button>
    """
  end
end
