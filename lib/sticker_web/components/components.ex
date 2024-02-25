defmodule StickerWeb.Components do
  use StickerWeb, :html

  @bgs [
    "bg-green-50",
    "bg-pink-50",
    "bg-blue-50",
    "bg-red-50",
    "bg-gray-50",
    "bg-orange-100",
    "bg-teal-50"
  ]
  @text_colors [
    "text-green-300",
    "text-pink-300",
    "text-blue-300",
    "text-red-300",
    "text-gray-300",
    "text-orange-300",
    "text-teal-300"
  ]

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :prediction, :map, required: true

  def sticker(assigns) do
    ~H"""
    <div class={@class}>
      <.image id={@id} prediction={@prediction} />
    </div>
    """
  end

  defp image(assigns) do
    color_index = Enum.random(0..6)
    bg = Enum.at(@bgs, color_index)
    text_color = Enum.at(@text_colors, color_index)

    ~H"""
    <.link navigate={~p"/sticker/#{@prediction.id}"}>
      <span class="bg-green-50 bg-blue-50 bg-pink-50 bg-red-50 bg-gray-50 bg-orange-100 bg-teal-50 hidden">
      </span>
      <span class="text-green-500 text-pink-500 text-blue-500 text-red-500 text-gray-500 text-orange-500 text-teal-500 hidden">
      </span>

      <div class={"group aspect-h-10 aspect-w-10 block overflow-hidden rounded-lg #{bg} focus-within:ring-2 focus-within:ring-black-500 focus-within:ring-offset-2 focus-within:ring-offset-gray-100"}>
        <%= if is_nil(@prediction.sticker_output) and is_nil(@prediction.no_bg_output) do %>
          <div class="flex items-center justify-center h-36">
            <p class="animate-pulse ">Loading...</p>
          </div>
        <% else %>
          <button
            id={"prediction-#{@id}-btn"}
            phx-value-name={@prediction.prompt}
            phx-value-image={@prediction.sticker_output}
            type="button"
          >
            <img
              src={@prediction.sticker_output}
              alt={@prediction.prompt}
              class="pointer-events-none object-cover group-hover:opacity-75"
            />
          </button>
        <% end %>
      </div>

      <div class="flex justify-between mt-2">
        <span class="block truncate text-sm font-medium text-gray-900">
          <%= @prediction.prompt %>
        </span>
        <span :if={@prediction.score != 0} class={"inline-flex text-sm font-bold #{text_color}"}>
          <%= @prediction.score %>
        </span>
      </div>
    </.link>
    """
  end
end
