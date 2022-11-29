defmodule HnAggregatorWeb.UserSocket do
  use Phoenix.Socket

  channel "hn:top_stories", HnAggregatorWeb.TopStoriesChannel

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
