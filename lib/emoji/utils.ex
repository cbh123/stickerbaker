defmodule Emoji.Utils do
  @preprompt "A TOK emoji of a "

  def preprompt, do: @preprompt

  def humanize(name) do
    dasherize(name)
  end

  defp dasherize(name) do
    name
    |> String.replace(@preprompt, "")
    |> String.replace("A TOK emoji of an ", "")
    |> String.split(" ")
    |> Enum.join("-")
    |> String.replace("--", "-")
  end
end
