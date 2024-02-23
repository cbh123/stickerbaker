defmodule Sticker.SearchTest do
  use Sticker.DataCase

  alias Sticker.Search

  describe "queries" do
    alias Sticker.Search.Query

    import Sticker.SearchFixtures

    @invalid_attrs %{content: nil, embedding: nil}

    test "list_queries/0 returns all queries" do
      query = query_fixture()
      assert Search.list_queries() == [query]
    end

    test "get_query!/1 returns the query with given id" do
      query = query_fixture()
      assert Search.get_query!(query.id) == query
    end

    test "create_query/1 with valid data creates a query" do
      valid_attrs = %{content: "some content", embedding: "some embedding"}

      assert {:ok, %Query{} = query} = Search.create_query(valid_attrs)
      assert query.content == "some content"
      assert query.embedding == "some embedding"
    end

    test "create_query/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Search.create_query(@invalid_attrs)
    end

    test "update_query/2 with valid data updates the query" do
      query = query_fixture()
      update_attrs = %{content: "some updated content", embedding: "some updated embedding"}

      assert {:ok, %Query{} = query} = Search.update_query(query, update_attrs)
      assert query.content == "some updated content"
      assert query.embedding == "some updated embedding"
    end

    test "update_query/2 with invalid data returns error changeset" do
      query = query_fixture()
      assert {:error, %Ecto.Changeset{}} = Search.update_query(query, @invalid_attrs)
      assert query == Search.get_query!(query.id)
    end

    test "delete_query/1 deletes the query" do
      query = query_fixture()
      assert {:ok, %Query{}} = Search.delete_query(query)
      assert_raise Ecto.NoResultsError, fn -> Search.get_query!(query.id) end
    end

    test "change_query/1 returns a query changeset" do
      query = query_fixture()
      assert %Ecto.Changeset{} = Search.change_query(query)
    end
  end
end
