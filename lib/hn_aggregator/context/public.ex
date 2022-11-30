defmodule HnAggregator.Public do
  @moduledoc """
  Public module that will be called direct from controller respecting the isolation between controller and schema.

  If additional rules or validations are necessary before fetching the data they should be put here to isolate the business module form the api.
  """

  alias HnAggregator.Schema

  require Logger

  @doc """
  Retrives all stories from the data source.
  """
  @spec get_all_top_stories() :: {:ok, list()}
  def get_all_top_stories do
    case Schema.get_all() do
      [] ->
        Logger.warn("No stories were found")

        {:ok, []}

      data ->
        {:ok, data}
    end
  end

  @doc """
  This function retrives the first page because no next page offset is given here
  """
  @spec get_paginated_data :: {:ok, {[map], binary}}
  def get_paginated_data do
    {:ok, {next_page, data}} = Schema.get_paginated(nil)

    {:ok, {data, next_page}}
  end

  @spec get_paginated_data(nil | binary) ::
          {:error, :invalid_offset} | {:ok, {binary, [struct()]}}
  def get_paginated_data(next_page) do
    case Schema.get_paginated(next_page) do
      {:ok, {next_page, data}} ->
        {:ok, {data, next_page}}

      {:error, :invalid_offset} ->
        {:error, :invalid_offset}

      {:error, :invalid_binary_offset} ->
        {:error, :invalid_offset}
    end
  end
end
