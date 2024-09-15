defmodule Project73Web.BaseComponents do
  use Phoenix.Component

  attr :class, :string, default: nil
  attr :method, :string, default: "get"
  attr :href, :string, required: true
  slot :inner_block, required: true

  def redirect_button(assigns) do
    ~H"""
    <.link
      href={@href}
      method={@method}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
