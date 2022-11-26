defmodule HnAggregator.DataPollerTest do
  use ExUnit.Case

  alias HnAggregator.DataPoller

  describe "start_link/1" do
    setup do
      {:ok, pid} = GenServer.start_link(DataPoller, [])

      %{
        pid: pid
      }
    end

    test "it starts with default poll interval", %{pid: pid} do
      assert :sys.get_state(pid).poll_interval == 300
    end

    test "it starts with default max retries", %{pid: pid} do
      assert :sys.get_state(pid).max_retries == 5
    end

    test "it starts with default data", %{pid: pid} do
      assert :sys.get_state(pid).data == []
    end

    test "it starts with default HN endpoint", %{pid: pid} do
      assert :sys.get_state(pid).hn_endpoint ==
               "https://hacker-news.firebaseio.com/v0/topstories.json"
    end

    test "it accepts named module as argument" do
      {:ok, _pid} = DataPoller.start_link(name: TestPoller)

      pid = GenServer.whereis(TestPoller)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end
  end
end
