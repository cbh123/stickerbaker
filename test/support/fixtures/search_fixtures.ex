defmodule Sticker.SearchFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sticker.Search` context.
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
      |> Sticker.Search.create_query()

    query
  end
end
