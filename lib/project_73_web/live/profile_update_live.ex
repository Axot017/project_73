defmodule Project73Web.ProfileUpdateLive do
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
     |> assign(profile: profile, actor_pid: pid, form: to_form(%{})), layout: false}
  end

  def handle_event(
        "save",
        %{
          "username" => username,
          "first_name" => first_name,
          "last_name" => last_name,
          "country" => country,
          "city" => city,
          "address_line1" => address_line1,
          "address_line2" => address_line2,
          "postal_code" => postal_code
        },
        socket
      ) do
    profile_params = %{
      username: username,
      first_name: first_name,
      last_name: last_name,
      country: country,
      city: city,
      address_line1: address_line1,
      address_line2: address_line2,
      postal_code: postal_code
    }

    :ok = Profile.Actor.update_profile(socket.assigns.actor_pid, profile_params)

    {:noreply, redirect(socket, to: ~p"/auth/refresh")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-gray-800 rounded-lg shadow-xl p-8 max-w-md w-full">
        <h2 class="text-3xl font-bold text-center text-gray-100 mb-8">Set Up Your Account</h2>
        <.form for={@form} phx-submit="save" class="space-y-6">
          <.input
            label="Username"
            name="username"
            value={@profile.username}
            field={@form[:username]}
            minlength="3"
            required
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="First Name"
            name="first_name"
            value=""
            field={@form[:first_name]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Last Name"
            name="last_name"
            value=""
            field={@form[:last_name]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Country"
            name="country"
            value=""
            field={@form[:country]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="City"
            name="city"
            value=""
            field={@form[:city]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Address Line 1"
            name="address_line1"
            value=""
            field={@form[:address_line1]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Address Line 2"
            name="address_line2"
            value=""
            field={@form[:address_line2]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Postal Code"
            name="postal_code"
            value=""
            field={@form[:postal_code]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
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
