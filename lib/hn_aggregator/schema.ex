defmodule HnAggregator.Schema do
  @moduledoc """
  Schema that stores the HN data into memory.

  It was built to support more than one type of data source, it need to be implemented but it then can be given as an argument when starting the GenServer.

  Arguments:

  - `data_source` type of data source to store data, default `:mnesia`
  - `table_name` the name of the data source table to save the data
  - `name` the module name to be given at start_link/1
  """

  use GenServer

  alias :mnesia, as: Mnesia
  alias HnAggregator.Model

  @hn_data_table HnData

  require Logger

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(args) do
    data_source = Keyword.get(args, :data_source, :mnesia)
    table_name = Keyword.get(args, :table_name, @hn_data_table)

    create(data_source, table_name)

    {:ok, %{data_source: data_source, table_name: table_name}}
  end

  @doc """
  Saves the given data to the data source

  - `data` is an array of ids to be saved
  """
  def save(data, name \\ __MODULE__) do
    GenServer.call(name, {:save, data})
  end

  @doc """
  Retrieves all records from the data source
  """
  @spec get_all(module()) :: [Model.t()]
  def get_all(name \\ __MODULE__) do
    GenServer.call(name, :get_all)
  end

  @doc """
  Gets the records paginated by 10 records per page.

  `cont` - the offset to get the next page, if nil returns the first page

  Returns the data and the next offset to continue
  """
  @spec get_paginated(binary() | nil, module()) ::
          {:ok, {binary(), [Model.t()]}}
          | {:error, :invalid_offset}
          | {:error, :invalid_binary_offset}
  def get_paginated(cont, name \\ __MODULE__)

  def get_paginated(cont, name) do
    GenServer.call(name, {:get_paginated, cont})
  end

  @doc """
  Marks all data as expired by setting the attribute `expired_data` as true
  """
  def mark_data_as_expired(name \\ __MODULE__) do
    GenServer.call(name, :mark_data_as_expired)
  end

  @doc """
  This function was created to be used at testing cases that needs fresh table before each test
  """
  def clear_table(name \\ __MODULE__) do
    GenServer.call(name, :clear_table)
  end

  @doc """
  Creates the schema based on its given atom parameter.

  :mnesia -> will create a mnesia schema to save the data and use it as data source

  It's possible to support different types of schemas, if necessary, like ets, for example.
  """
  def create(:mnesia, table_name) do
    Mnesia.create_schema([node()])

    Mnesia.start()

    Mnesia.create_table(table_name,
      attributes: [:id, :fetch_uri, :expired_data],
      type: :ordered_set
    )
  end

  def handle_call(:clear_table, _from, %{data_source: :mnesia, table_name: table_name} = state) do
    Mnesia.transaction(fn ->
      Mnesia.clear_table(table_name)
    end)

    {:reply, :ok, state}
  end

  def handle_call({:save, data}, _from, %{data_source: :mnesia, table_name: table_name} = state) do
    Mnesia.transaction(fn ->
      Mnesia.clear_table(table_name)
    end)

    result =
      Mnesia.transaction(fn ->
        Enum.map(data, fn item_id ->
          Mnesia.write(
            {table_name, item_id, "https://hacker-news.firebaseio.com/v0/item/#{item_id}.json?",
             false}
          )
        end)
      end)
      |> case do
        {:atomic, _results} ->
          Logger.warn("Records successfully saved to mnesia")
          :ok

        {:aborted, _results} ->
          {:error, :invalid_data}
      end

    {:reply, result, state}
  end

  def handle_call(:get_all, _from, %{data_source: :mnesia, table_name: table_name} = state) do
    {:atomic, data} =
      Mnesia.transaction(fn ->
        Mnesia.match_object({table_name, :_, :_, :_})
      end)

    model_data = Model.new(:mnesia, data)

    {:reply, model_data, state}
  end

  def handle_call(
        {:get_paginated, nil},
        _from,
        %{data_source: :mnesia, table_name: table_name} = state
      ) do
    match_spec = [{{table_name, :"$1", :"$2", :"$3"}, [{:>, :"$1", 0}], [:"$$"]}]

    {data, cont} =
      Mnesia.async_dirty(fn ->
        Mnesia.select(table_name, match_spec, 10, :read)
      end)

    cont = :erlang.term_to_binary(cont) |> Base.encode64()
    model_data = Model.new(:mnesia, data)

    {:reply, {:ok, {cont, model_data}}, state}
  end

  def handle_call({:get_paginated, cont}, _from, %{data_source: :mnesia} = state) do
    with {:ok, decoded_offset} <- decode_base64_offset(cont),
         {:ok, parsed_offset} <- parse_binary_offset(decoded_offset),
         {:ok, result} <- mnesia_do_offset_select(parsed_offset) do
      {:reply, {:ok, result}, state}
    else
      {:error, :invalid_offset} ->
        {:reply, {:error, :invalid_offset}, state}

      {:error, :invalid_binary_offset} ->
        {:reply, {:error, :invalid_binary_offset}, state}

      {:error, :invalid_offset_term} ->
        {:reply, {:error, :invalid_offset_term}, state}
    end
  end

  def handle_call(
        :mark_data_as_expired,
        _from,
        %{data_source: :mnesia, table_name: table_name} = state
      ) do
    Mnesia.transaction(fn ->
      data = Mnesia.match_object(table_name, {table_name, :_, :_, false}, :write)

      Enum.map(data, fn {table, id, uri, _expired_data} ->
        Mnesia.write({table, id, uri, true})
      end)
    end)

    {:reply, :ok, state}
  end

  defp decode_base64_offset(offset) do
    case Base.decode64(offset) do
      {:ok, cont} ->
        {:ok, cont}

      :error ->
        {:error, :invalid_offset}
    end
  end

  defp parse_binary_offset(offset) do
    try do
      mnesia_offest = :erlang.binary_to_term(offset)

      {:ok, mnesia_offest}
    rescue
      ArgumentError -> {:error, :invalid_binary_offset}
    end
  end

  defp mnesia_do_offset_select(offset) do
    try do
      Mnesia.async_dirty(fn ->
        Mnesia.select(offset)
      end)
      |> case do
        :"$end_of_table" ->
          {:ok, {:end_of_page, []}}

        {:error, _error} ->
          {:error, :invalid_offset_term}

        {data, cont} ->
          cont = :erlang.term_to_binary(cont) |> Base.encode64()
          model_data = Model.new(:mnesia, data)

          {:ok, {cont, model_data}}
      end
    catch
      error ->
        IO.inspect(error, label: :error)
        {:error, error}
    end
  end
end
