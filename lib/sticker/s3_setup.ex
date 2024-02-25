defmodule Sticker.S3Setup do
  alias ExAws.S3

  def set_cors(bucket_name) do
    cors_rules =
      [
        %{
          allowed_origins: ["*"],
          allowed_methods: ["GET"],
          allowed_headers: ["*"],
          # Assuming you don't need to expose any headers, but adjust as necessary
          exposed_headers: [],
          max_age_seconds: 3000
        }
      ]

    bucket_name
    |> S3.put_bucket_cors(cors_rules)
    |> ExAws.request!()
  end
end
