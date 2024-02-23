defmodule Sticker.Utils do
  @preprompt "A TOK sticker of a "

  def preprompt, do: @preprompt

  def humanize(name) do
    dasherize(name)
  end

  defp dasherize(name) do
    name
    |> String.replace(@preprompt, "")
    |> String.replace("A TOK sticker of an ", "")
    |> String.split(" ")
    |> Enum.join("-")
    |> String.replace("--", "-")
  end
end
