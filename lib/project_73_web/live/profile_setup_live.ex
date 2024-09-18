defmodule Project73Web.ProfileSetupLive do
  require Logger
  alias Project73.Profile
  use Project73Web, :live_view

  def mount(_params, session, socket) do
    user_id = session["current_user"].id
    {:ok, pid} = Profile.Supervisor.get_actor(user_id)
    profile = Profile.Actor.get_profile(pid)
    Logger.debug("Profile loaded: #{inspect(profile)}")

    {:ok,
     socket
     |> assign(profile: profile, actor_pid: pid, form: to_form(%{}))
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign(:uploaded_files, []), layout: false}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"username" => username}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        dest = Path.join(["priv", "static", "uploads", Path.basename(path)])
        File.mkdir_p!(Path.dirname(dest))
        Logger.debug("Copying file from #{path} to #{dest}, entry: #{inspect(entry)}")
        File.cp!(path, dest)
        {:ok, "/uploads/" <> Path.basename(dest)}
      end)

    avatar_url = List.first(uploaded_files)

    profile_params = %{username: username, avatar_url: avatar_url}
    :ok = Profile.Actor.update_profile(socket.assigns.actor_pid, profile_params)

    {:noreply, redirect(socket, to: ~p"/auth/refresh")}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-gray-800 rounded-lg shadow-xl p-8 max-w-md w-full">
        <h2 class="text-3xl font-bold text-center text-gray-100 mb-8">Set Up Your Account</h2>
        <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
          <.input
            label="Username"
            name="username"
            value={@profile.username}
            field={@form[:username]}
            minlength="3"
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />

          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-300">
              Profile Picture
            </label>
            <div class="flex items-center space-x-4">
              <%= if @profile.avatar_url do %>
                <img
                  src={@profile.avatar_url}
                  alt="Current avatar"
                  class="h-12 w-12 rounded-full object-cover"
                />
              <% else %>
                <div class="h-12 w-12 rounded-full bg-gray-700 flex items-center justify-center">
                  <svg
                    class="h-6 w-6 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                    />
                  </svg>
                </div>
              <% end %>
              <label
                for={@uploads.avatar.ref}
                class="cursor-pointer bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded-md transition duration-300 ease-in-out"
              >
                Choose File
              </label>
              <.live_file_input upload={@uploads.avatar} class="hidden" />
            </div>
            <%= for entry <- @uploads.avatar.entries do %>
              <div class="mt-2 flex items-center space-x-2">
                <.live_img_preview entry={entry} class="h-10 w-10 rounded-full object-cover" />
                <div class="text-sm text-gray-300"><%= entry.client_name %></div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-red-500 hover:text-red-700"
                >
                  &times;
                </button>
              </div>
            <% end %>
            <%= for err <- upload_errors(@uploads.avatar) do %>
              <p class="mt-2 text-sm text-red-500"><%= err %></p>
            <% end %>
          </div>

          <.button
            type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-md transition duration-300 ease-in-out"
          >
            Save
          </.button>
        </.form>
      </div>
    </div>
    """
  end
end
