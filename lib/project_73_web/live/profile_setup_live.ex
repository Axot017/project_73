defmodule Project73Web.ProfileLive do
  require Logger
  alias Project73.Profile
  use Project73Web, :live_view

  def mount(_params, session, socket) do
    user_id = session["current_user"].id
    {:ok, pid} = Profile.Supervisor.get_actor(user_id)
    profile = Profile.Actor.get_profile(pid)

    Logger.debug("Profile loaded: #{inspect(profile)}")

    {:ok, assign(socket, profile: profile, actor_pid: pid, form: %{}), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.simple_form for={@form} phx-submit="save">
      <.input label="Username" name="username" value="" field={@form[:username]} minlength="3" />
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def handle_event("save", %{"username" => username}, socket) do
    :ok = Profile.Actor.update_profile(socket.assigns.actor_pid, %{username: username})

    {:noreply, redirect(socket, to: ~p"/auth/refresh")}
  end
end
