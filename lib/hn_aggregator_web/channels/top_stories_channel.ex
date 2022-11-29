defmodule HnAggregatorWeb.TopStoriesChannel do
  use HnAggregatorWeb, :channel

  @impl true
  def join("hn:top_stories", _payload, socket) do
    {:ok, socket}
  end

  intercept ["hn_new_data"]

  @impl true
  def handle_out("hn_new_data", %{"data" => data}, socket) do
    push(socket, "hn_new_data", %{"data" => data})

    {:noreply, socket}
  end
end
