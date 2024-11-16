defmodule Project73Web.NewAuctionLive do
  require Logger
  use Project73Web, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       form:
         to_form(%{
           "title" => "",
           "description" => "",
           "initial_price" => ""
         })
     )
     |> allow_upload(:images, accept: ~w(.jpg .jpeg .png), max_entries: 5)}
  end

  def handle_event("validate", %{"_target" => _targets}, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "save",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
        <.input
          label="Title"
          field={@form[:title]}
          class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
        />
        <.input
          label="Description"
          field={@form[:description]}
          class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
        />
        <.input
          label="Initial Price"
          type="number"
          field={@form[:initial_price]}
          class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
        />
        <div phx-drop-target={@uploads.images.ref}>
          <.live_file_input upload={@uploads.images} />
        </div>
        <%= for entry <- @uploads.images.entries do %>
          <.live_img_preview entry={entry} width="75" />
        <% end %>
        <.button
          type="submit"
          class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-md transition duration-300 ease-in-out"
        >
          Creaet Auction
        </.button>
      </.simple_form>
    </div>
    """
  end
end
