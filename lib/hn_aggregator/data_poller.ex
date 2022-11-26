defmodule HnAggregator.DataPoller do
  @moduledoc """
  Module responsible to poll data from HN api and store it into the given Schema.

  Available configurations are:

  - `poll_interval` interval in seconds to poll the data from HN, defaults to 300.
  - `hn_endpoint` HN endpoint to poll the data from, defaults to `https://hacker-news.firebaseio.com/v0/topstories.json`.
  - `max_retries` Number of retries to poll the data before marking a failure at the poll endpoint, default value is 5.

  The data poller will have an exponential backoff in case of failures, the rule is simple, the nex poll will happen after current_retry x 60 so,
  for instance, the retry after the first failure will happen 1 x 60, after 60 seconds.
  """

  use GenServer

  require Logger

  alias HnAggregator.Schema

  @hn_top_stories_endpoint "https://hacker-news.firebaseio.com/v0/topstories.json"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    poll_interval = Keyword.get(args, :poll_interval, 300)
    hn_endpoint = Keyword.get(args, :hn_endpoint, @hn_top_stories_endpoint)
    max_retries = Keyword.get(args, :max_retries, 5)

    schedule_next_poll(5)

    {:ok,
     %{
       poll_interval: poll_interval,
       data: [],
       hn_endpoint: hn_endpoint,
       retries: 0,
       max_retries: max_retries
     }}
  end

  @doc """
  Polls the data from hacker news and pass it to the next function to process.
  """
  def handle_info(
        :poll,
        %{poll_interval: poll_interval, hn_endpoint: hn_endpoint, retries: retries} = state
      ) do
    with {:ok, {{_, 200, _}, _header, body}} <- :httpc.request(hn_endpoint),
         {:ok, data} <- parse_response(body) do
      schedule_next_poll(poll_interval)

      {:noreply, %{state | data: data, retries: 0}, {:continue, :process_response}}
    else
      {:ok, {{_, status_code, _}, _header, _body}} ->
        Logger.error("HTTP call failed due to unsupported status code #{status_code}")

        {:noreply, %{state | data: state.data, retries: retries + 1},
         {:continue, :process_http_invalid_status}}

      {:error, %Jason.DecodeError{} = error} ->
        Logger.error(error)

        {:noreply, %{state | data: state.data, retries: retries + 1},
         {:continue, :process_http_invalid_status}}
    end
  end

  @doc """
  Handle continue are called after a poll is made on the given HN endpoint. The following are each message:

  - `:process_response` a successfull call was made and no errors were found, it will continue by saving the data at the given Schema.
  - `process_http_invalid_status` an unsupported http status code was returned, it will increase the number of retries and try again based on its exponential backoff rule
  """
  def handle_continue(:process_response, %{data: data} = state) do
    to_save_data = Enum.take(data, 50)

    Schema.save(to_save_data)

    {:noreply, state}
  end

  def handle_continue(:process_http_invalid_status, _state) do
  end

  defp parse_response(body) do
    Jason.decode(body)
  end

  defp schedule_next_poll(interval) do
    Process.send_after(self(), :poll, :timer.seconds(interval))
  end
end
