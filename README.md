# StickerBaker

<blockquote class="twitter-tweet" data-media-max-width="560"><p lang="en" dir="ltr">Announcing StickerBaker!<br><br>Make stickers with AI. Powered by <a href="https://twitter.com/replicate?ref_src=twsrc%5Etfw">@replicate</a> and <a href="https://twitter.com/flydotio?ref_src=twsrc%5Etfw">@flydotio</a>, and 100% open-source.<a href="https://t.co/8vucCsHtAd">https://t.co/8vucCsHtAd</a> <a href="https://t.co/tBhDyGrOx0">pic.twitter.com/tBhDyGrOx0</a></p>&mdash; Charlie Holtz (@charliebholtz) <a href="https://twitter.com/charliebholtz/status/1762232726361633018?ref_src=twsrc%5Etfw">February 26, 2024</a></blockquote>

## How it works

Enter a prompt and generating a sticker using https://replicate.com/fofr/sticker-maker. Then, click to download and add to slack!

StickerBaker runs on:
- [Replicate](https://replicate.com/fofr/sticker-maker?utm_source=project&utm_campaign=stickerbaker) to generate the stickers
- [Fly.io](https://fly.io) for infrastructure
- [Tigris](https://www.tigrisdata.com) for image hosting

## Dev

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- Add a .env file with REPLICATE_API_TOKEN set to your [Replicate](https://replicate.com/) token

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
