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
    <.form for={@form} phx-submit="save">
      <.input type="text" name="username" value="" field={@form[:username]} />

      <.button>Save</.button>
    </.form>
    """
  end

  def handle_event("save", %{"username" => username}, socket) do
    user_id = socket.assigns.profile.id
    Logger.debug("Saving profile for user_id: #{user_id}: #{username}")

    {:noreply, redirect(socket, to: ~p"/auction")}
  end
end
