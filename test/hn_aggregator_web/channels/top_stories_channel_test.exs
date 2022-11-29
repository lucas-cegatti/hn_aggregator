defmodule HnAggregatorWeb.TopStoriesChannelTest do
  use HnAggregatorWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      HnAggregatorWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(HnAggregatorWeb.TopStoriesChannel, "hn:top_stories")

    %{socket: socket}
  end

  test "broadcast new hn story", %{socket: socket} do
    broadcast_from!(socket, "hn_new_data", %{"data" => []})

    assert_push "hn_new_data", %{"data" => []}
  end
end
