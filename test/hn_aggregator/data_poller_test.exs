defmodule HnAggregator.DataPollerTest do
  use ExUnit.Case

  alias HnAggregator.DataPoller

  @test_poller_module TestPoller

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
      {:ok, _pid} = DataPoller.start_link(name: @test_poller_module)

      pid = GenServer.whereis(@test_poller_module)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "it replaces default poll interval" do
      {:ok, pid} = DataPoller.start_link(poll_interval: 120, name: @test_poller_module)

      assert :sys.get_state(pid).poll_interval == 120
    end

    test "it replaces default max retries" do
      {:ok, pid} = DataPoller.start_link(max_retries: 10, name: @test_poller_module)

      assert :sys.get_state(pid).max_retries == 10
    end

    test "it replaces default HN endpoint" do
      {:ok, pid} =
        DataPoller.start_link(
          hn_endpoint: "https://fake-http.fly.dev/api/500",
          name: @test_poller_module
        )

      assert :sys.get_state(pid).hn_endpoint == "https://fake-http.fly.dev/api/500"
    end
  end

  describe "poll" do
    test "it increases number of retries when not 200 is returned" do

    end
  end
end
