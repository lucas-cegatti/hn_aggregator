defmodule HnAggregatorWeb.AggregatorController do
  @moduledoc """
  Controller module that provide the api to fetch paginated data from the data source.

  Params

  - `next_page` retrieves the next page from the schema

  Response

  The response is in the json format and will follow the schema:

  - `id` integer - the id of the story
  - `detail_url` string - the url to fetch the story detail
  - `expired_data` boolean - mark if this data is expired, meaning that we could not get updated data in the past 5 minutes
  - `next_page` string indicates if theres a next page to be fetch, it returns a base64 offset or `end_of_page` if there's no page

  *Example*
  Succesfull response:
  ```json
  {
    "data": [
      {
        "id": 33786502,
        "detail_url": "https://hacker-news.firebaseio.com/v0/item/33786502.json",
        "expired_data": false
      }
    ],
    "next_page": "g2gKZAANbW5lc2lhX3NlbGVjdGQADUVsaXhpci5IbkRhdGFoAmQAC2FzeW5jX2RpcnR5WGQADW5vbm9kZUBub2hvc3QAAAFPAAAAAAAAAABkAA1ub25vZGVAbm9ob3N0ZAAKcmFtX2NvcGllc2gIZAANRWxpeGlyLkhuRGF0YWEfamEKWgADZAANbm9ub2RlQG5vaG9zdAAAAAAAAOeQrg4ABbZhbuBqYQBhAGpkAAl1bmRlZmluZWRkAAl1bmRlZmluZWRsAAAAAWgDaARkAA1FbGl4aXIuSG5EYXRhZAACJDFkAAIkMmQAAiQzbAAAAAFoA2QAAT5kAAIkMWEAamwAAAABZAACJCRqag=="
  }
  ```

  Error Response:
  ```json
  {
    "type": "error",
    "message":  "invalid_offset"
  }
  ```
  """
  use HnAggregatorWeb, :controller

  alias HnAggregator.Public

  def top_stories(conn, %{"next_page" => next_page}) do
    case Public.get_paginated_data(next_page) do
      {:ok, {data, next_page}} ->
        render(conn, "top_stories.json", top_stories: data, next_page: next_page)

      {:error, error} ->
        render(conn, "error.json", message: error)
    end
  end

  def top_stories(conn, _params) do
    {:ok, {data, next_page}} = Public.get_paginated_data()

    render(conn, "top_stories.json", top_stories: data, next_page: next_page)
  end
end
