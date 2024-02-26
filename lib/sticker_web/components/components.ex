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
          <div class="flex items-center justify-center h-48">
            <div role="status">
              <svg
                aria-hidden="true"
                class="w-8 h-8 text-white animate-spin fill-blue-600"
                viewBox="0 0 100 101"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                  fill="currentColor"
                />
                <path
                  d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                  fill="currentFill"
                />
              </svg>
              <span class="sr-only">Loading...</span>
            </div>
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
        <span :if={@prediction.score > 0} class={"inline-flex text-sm font-bold #{text_color}"}>
          <%= @prediction.score %>
        </span>
      </div>
    </.link>
    """
  end
end
