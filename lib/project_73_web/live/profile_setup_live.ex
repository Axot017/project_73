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
    <div class="min-h-screen bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-gray-800 rounded-lg shadow-xl p-8 max-w-md w-full">
        <h2 class="text-3xl font-bold text-center text-gray-100 mb-8">Set Up Your Account</h2>
        <.simple_form for={@form} phx-submit="save" class="space-y-6">
          <.input
            label="Username"
            name="username"
            value=""
            field={@form[:username]}
            minlength="3"
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
            label_class="block text-sm font-medium text-gray-300"
          />
          <:actions>
            <.button class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-md transition duration-300 ease-in-out">
              Save
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"username" => username}, socket) do
    :ok = Profile.Actor.update_profile(socket.assigns.actor_pid, %{username: username})

    {:noreply, redirect(socket, to: ~p"/auth/refresh")}
  end
end
