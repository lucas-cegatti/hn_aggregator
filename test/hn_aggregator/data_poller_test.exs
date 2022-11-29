defmodule HnAggregator.DataPollerTest do
  use ExUnit.Case

  alias HnAggregator.{DataPoller, Schema}

  import ExUnit.CaptureLog

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

  describe "handle_info/2 :poll" do
    setup do
      state = %{
        poll_interval: 300,
        hn_endpoint: "https://hacker-news.firebaseio.com/v0/topstories.json",
        retries: 0,
        data: []
      }

      [
        state: state
      ]
    end

    test "it increases number of retries when status other then 200 is returned", %{state: state} do
      assert {:noreply, %{retries: 1, data: []}, {:continue, :process_error}} =
               DataPoller.handle_info(:poll, %{
                 state
                 | hn_endpoint: "https://fake-http.fly.dev/api/500"
               })
    end

    test "it fails on validation when a list is not returned on response", %{state: state} do
      assert capture_log(fn ->
               assert {:noreply, %{retries: 1, data: []}, {:continue, :process_error}} =
                        DataPoller.handle_info(:poll, %{
                          state
                          | hn_endpoint: "https://fake-http.fly.dev/api/200"
                        })
             end) =~ "HN response failed on validation, expected value is an array of integer"
    end

    test "it fails when an response other then json is returned", %{state: state} do
      assert capture_log(fn ->
               assert {:noreply, %{retries: 1, data: []}, {:continue, :process_error}} =
                        DataPoller.handle_info(:poll, %{
                          state
                          | hn_endpoint: "https://fake-http.fly.dev/api/200?response_type=html"
                        })
             end) =~ "Could not parse response, json is expected"
    end

    test "it successfully retrives and parse a message from HN", %{state: state} do
      assert {:noreply, %{data: data, retries: 0}, {:continue, :process_response}} =
               DataPoller.handle_info(:poll, state)

      assert length(data) == 500
    end
  end

  describe "handle_continue/2 :process_error" do
    setup do
      state = %{
        poll_interval: 300,
        hn_endpoint: "https://hacker-news.firebaseio.com/v0/topstories.json",
        retries: 0,
        max_retries: 5,
        data: []
      }

      [
        state: state
      ]
    end

    test "it does not schedule next process when max retries is reached", %{state: state} do
      assert capture_log(fn ->
               assert {:noreply, state} =
                        DataPoller.handle_continue(:process_error, %{state | retries: 5})

               assert nil == Map.get(state, :time_ref)
             end) =~ "Max retries reached, data polling will be halted until manual start"
    end

    test "it schedules next process if max retries is not reached", %{state: state} do
      assert {:noreply, new_state} =
               DataPoller.handle_continue(:process_error, %{state | retries: 1})

      assert :timer.seconds(60) == Process.read_timer(new_state.time_ref)
    end

    test "next retry is increased considering the current number of retries", %{state: state} do
      assert {:noreply, new_state} =
               DataPoller.handle_continue(:process_error, %{state | retries: 4})

      assert :timer.seconds(60 * 4) == Process.read_timer(new_state.time_ref)
    end
  end

  describe "handle_continue/2 process_response" do
    setup do
      state = %{
        poll_interval: 300,
        hn_endpoint: "https://hacker-news.firebaseio.com/v0/topstories.json",
        retries: 0,
        max_retries: 5,
        data: []
      }

      [
        state: state
      ]
    end

    test "it saves a list of stories to schema", %{state: state} do
      data = StreamData.positive_integer() |> Enum.take(500) |> Enum.uniq()

      assert {:noreply, _state} =
               DataPoller.handle_continue(:process_response, %{state | data: data})

      saved_data = Schema.get_all()

      assert length(saved_data) == 50
    end
  end
end
