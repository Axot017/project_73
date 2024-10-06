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
       amount_to_deposit: nil,
       stripe_public_key: @stripe_public_key
     )}
  end

  def handle_event("deposit", _params, socket) do
    pid = socket.assigns.actor_pid
    {:ok, deposit_data} = Profile.Actor.request_deposit(pid, Decimal.new("1000.00"))
    Logger.debug("Deposit data: #{inspect(deposit_data)}")

    {:noreply,
     socket
     |> push_event("start_deposit", %{client_secret: deposit_data.client_secret})
     |> assign(amount_to_deposit: deposit_data.amount)}
  end

  def render(assigns) do
    ~H"""
    <script>
      window.addEventListener("phx:start_deposit", (event) => {
      const stripe = Stripe("<%= @stripe_public_key %>");

      const elements = stripe.elements({ clientSecret: event.detail.client_secret, appearance: { theme: "night" } });
      const paymentElement = elements.create("payment");
      paymentElement.mount("#payment-element");

      });
    </script>
    <div>
      <%= Decimal.to_string(@current_user.wallet_balance) %>
    </div>
    <.modal :if={@amount_to_deposit} id="payment-modal" show>
      <.simple_form action="" for={%{}} id="payment-form">
        <div id="payment-element"></div>
        <.button type="submit">Submit Payment</.button>
      </.simple_form>
    </.modal>
    <.button phx-click="deposit">Deposit</.button>
    """
  end
end
