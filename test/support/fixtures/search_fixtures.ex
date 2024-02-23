defmodule Emoji.SearchFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Emoji.Search` context.
  """

  @doc """
  Generate a query.
  """
  def query_fixture(attrs \\ %{}) do
    {:ok, query} =
      attrs
      |> Enum.into(%{
        content: "some content",
        embedding: "some embedding"
      })
      |> Emoji.Search.create_query()

    query
  end
end
