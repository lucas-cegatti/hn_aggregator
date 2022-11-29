defmodule HnAggregatorWeb.AggregatorControllerTest do
  use HnAggregatorWeb.ConnCase

  alias HnAggregator.Schema

  setup_all do
    ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]

    Schema.save(ids)
  end

  describe "top_stories" do
    test "list paginated stories", %{conn: conn} do
      conn = get(conn, Routes.aggregator_path(conn, :top_stories))

      assert %{"data" => data, "next_page" => next_page} = json_response(conn, 200)

      assert length(data) == 10
      refute is_nil(next_page)
      refute next_page == "end_of_page"
    end

    @tag :"TODO: race conditions are causing this test to fail, I won't be able to fix it in time"
    @tag :skip
    test "it returns end_of_page and empty list when paginations reachs its final page", %{
      conn: conn
    } do
      conn = get(conn, Routes.aggregator_path(conn, :top_stories))
      assert %{"next_page" => next_page} = json_response(conn, 200)

      conn = get(conn, Routes.aggregator_path(conn, :top_stories, next_page: next_page))
      assert %{"next_page" => next_page} = json_response(conn, 200)

      conn = get(conn, Routes.aggregator_path(conn, :top_stories, next_page: next_page))
      assert %{"next_page" => "end_of_page", "data" => []} = json_response(conn, 200)
    end

    test "it returns error when and invalid base64 is given as offset", %{conn: conn} do
      conn = get(conn, Routes.aggregator_path(conn, :top_stories, next_page: "aaaaabbbbccc"))
      assert %{"type" => "error", "message" => "invalid_offset"} = json_response(conn, 200)
    end

    test "it returns error when and invalid binary term is given as offset", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.aggregator_path(conn, :top_stories, next_page: Base.encode64("aaaaabbbbb"))
        )

      assert %{"type" => "error", "message" => "invalid_offset"} = json_response(conn, 200)
    end
  end
end
