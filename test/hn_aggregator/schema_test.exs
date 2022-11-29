defmodule HnAggregator.SchemaTest do
  use ExUnit.Case

  alias HnAggregator.{Model, Schema}

  describe "save/1" do
    setup do
      on_exit(fn ->
        Schema.clear_table()
      end)
    end

    test "it saves a valid data set to the data source" do
      data = [1, 2, 3, 4, 5]

      assert :ok = Schema.save(data)
    end

    test "returns error on invalid data" do
      data = [{"1"}, "2", 3, 5]

      assert {:error, :invalid_data} = Schema.save(data)
    end
  end

  describe "get_all/0" do
    setup do
      on_exit(fn ->
        Schema.clear_table()
      end)
    end

    test "it retrieves all saved data" do
      Schema.start_link(name: GetAllTest, table_name: GetAllTest1)

      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
      Schema.save(data, GetAllTest)

      all_data = Schema.get_all(GetAllTest)

      assert length(all_data) == length(data)

      assert Enum.all?(all_data, fn %Model{id: id} ->
               Enum.member?(data, id)
             end)
    end

    test "it return empty list when no data is found" do
      Schema.start_link(name: GetAllTest, table_name: GetAllTest2)
      assert [] = Schema.get_all(GetAllTest)
    end
  end

  describe "mark_data_as_expired/0" do
    setup do
      on_exit(fn ->
        Schema.clear_table()
      end)
    end

    test "it marks all data as expired" do
      data = [1, 2, 3, 4, 5]
      Schema.save(data)

      Schema.mark_data_as_expired()

      expired_data = Schema.get_all()

      assert Enum.all?(expired_data, fn %Model{expired_data: expired_data} ->
               expired_data
             end)
    end
  end

  describe "get_paginated/1" do
    setup do
      on_exit(fn ->
        Schema.clear_table()
      end)
    end

    test "it gets paginated data with 10 records" do
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
      Schema.save(data)

      assert {:ok, {cont, data}} = Schema.get_paginated(nil)

      refute cont == :end_of_page

      assert length(data) == 10
    end

    test "it paginates until the end of the page" do
      Schema.start_link(name: PaginationTest, table_name: PaginationTest2)
      data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
      Schema.save(data, PaginationTest)

      assert {:ok, {cont, _data}} = Schema.get_paginated(nil, PaginationTest)
      assert {:ok, {cont, _data}} = Schema.get_paginated(cont, PaginationTest)
      assert {:ok, {:end_of_page, []}} = Schema.get_paginated(cont, PaginationTest)
    end

    test "it returns all records if length is less than pagination" do
      Schema.start_link(name: PaginationTest, table_name: PaginationTest3)
      data = [1, 2, 3, 4, 5]
      Schema.save(data, PaginationTest)

      assert {:ok, {cont, data}} = Schema.get_paginated(nil, PaginationTest)
      assert length(data) == 5
      assert {:ok, {:end_of_page, []}} = Schema.get_paginated(cont, PaginationTest)
    end

    test "it returns error when and invalid offset is given" do
      Schema.start_link(name: PaginationTest, table_name: PaginationTest4)
      data = [1, 2, 3, 4, 5]
      Schema.save(data, PaginationTest)

      invalid_base64 = "abbbccaaa"

      assert {:error, :invalid_offset} = Schema.get_paginated(invalid_base64, PaginationTest)
    end

    test "it returns error when an invalid binary offset is given" do
      Schema.start_link(name: PaginationTest, table_name: PaginationTest5)
      data = [1, 2, 3, 4, 5]
      Schema.save(data, PaginationTest)

      invalid_base64_binary = Base.encode64("aaaaabbbbb")

      assert {:error, :invalid_binary_offset} =
               Schema.get_paginated(invalid_base64_binary, PaginationTest)
    end

    "TODO: I couldn't find a way to capture the error when an invalid term is given to the offset"
    @tag :skip
    test "it returns error when and invalid term is given as on offset" do
      Schema.start_link(name: PaginationTest, table_name: PaginationTest6)
      data = [1, 2, 3, 4, 5]
      Schema.save(data, PaginationTest)

      invalid_term = {:some, :invalid, :term}

      invalid_base64_term = Base.encode64(:erlang.term_to_binary(invalid_term))

      assert {:error, :invalid_offset_term} = Schema.get_paginated(invalid_base64_term)
    end
  end
end
