defmodule HnAggregator.DataPoller do
  @moduledoc """
  Module responsible to poll data from HN api and store it into the default Schema at :mnesia
  """

  use GenServer

  @hn_top_stories_endpoint "https://hacker-news.firebaseio.com/v0/topstories.json"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    poll_interval = Keyword.get(args, :poll_interval, 300)
    hn_endpoint = Keyword.get(args, :hn_endpoint, @hn_top_stories_endpoint)

    schedule_next_poll(5)

    {:ok, %{poll_interval: poll_interval, data: [], hn_endpoint: hn_endpoint}}
  end

  @doc """
  Polls the data from hacker news e pass it to the next function to process.
  """
  def handle_info(:poll, %{poll_interval: poll_interval, hn_endpoint: hn_endpoint} = state) do
    schedule_next_poll(poll_interval)

    {:ok, data} =
      :httpc.request(hn_endpoint)
      |> handle_response()
      |> parse_response()
      |> IO.inspect(label: :response)

    {:noreply, %{state | data: data}, {:continue, :process_response}}
  end

  def handle_continue(:process_response, state) do
    IO.inspect(state.data, label: :process_response)

    {:noreply, state}
  end

  defp handle_response({:ok, {{_, 200, _}, _header, body}}) do
    {:ok, body}
  end

  defp parse_response({:ok, body}) do
    Jason.decode(body)
  end

  defp schedule_next_poll(interval) do
    Process.send_after(self(), :poll, :timer.seconds(interval))
  end
end
