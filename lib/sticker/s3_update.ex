defmodule Sticker.S3Utils do
  require ExAws

  def update_content_type(bucket_name) do
    bucket_name
    |> ExAws.S3.list_objects()
    |> ExAws.stream!()
    |> Enum.each(fn object ->
      object_key = object[:key]
      update_object_content_type(bucket_name, object_key)
    end)
  end

  def update_content_type_for_single_object(bucket_name, object_key) do
    update_object_content_type(bucket_name, object_key)
  end

  defp update_object_content_type(bucket, object_key) do
    object_content = ExAws.S3.get_object(bucket, object_key) |> ExAws.request!()

    case object_content do
      %{body: body} ->
        ExAws.S3.put_object(bucket, object_key, body, %{:content_type => "image/png"})
        |> ExAws.request()
        |> handle_response(object_key)

      :error ->
        IO.puts("Failed to get object #{object_key}: #{inspect(object_content)}")
    end
  end

  defp handle_response({:ok, _response}, object_key) do
    IO.puts("Updated Content-Type for #{object_key}")
  end

  defp handle_response({:error, reason}, object_key) do
    IO.puts("Failed to update Content-Type for #{object_key}: #{inspect(reason)}")
  end
end
