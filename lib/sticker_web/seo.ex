defmodule StickerWeb.SEO do
  use SEO,
    json_library: Jason,
    # a function reference will be called with a conn during render
    site: &__MODULE__.site_config/1,
    open_graph:
      SEO.OpenGraph.build(
        description: "Bake stickers with AI",
        site_name: "StickerBaker",
        locale: "en_US",
        image: "/og.webp"
      ),
    twitter:
      SEO.Twitter.build(
        site: "@charliebholtz",
        creator: ["@charliebholtz"],
        card: :summary,
        summary_card_image: "/og.webp"
      )

  def site_config(_conn) do
    SEO.Site.build(
      default_title: "StickerBaker | Make AI stickers",
      description: "Make AI stickers of yourself",
      theme_color: "#663399",
      windows_tile_color: "#663399",
      mask_icon_color: "#663399"
    )
  end
end
