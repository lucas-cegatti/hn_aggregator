defmodule HnAggregator.Schema do
  @moduledoc """
  Schema that stores the HN data into memory.

  It was built to support more than one type of data source, it need to be implemented but it then can be given as an argument when starting the GenServer.

  Arguments:

  - `data_source` type of data source to store data, default `:mnesia`
  """
  use GenServer

  alias :mnesia, as: Mnesia

  @hn_data_table HnData

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    data_source = Keyword.get(args, :data_source, :mnesia)

    create(data_source)

    {:ok, %{data_source: data_source}}
  end

  @doc """
  Saves the given data to the data source

  - `data` is an array of ids to be saved
  """
  def save(data) do
    GenServer.cast(__MODULE__, {:save, data})
  end

  def get_all() do
    Mnesia.transaction(fn ->
      Mnesia.match_object({@hn_data_table, :_, :_, :_})
    end)
  end

  def mark_data_as_expired() do
    Mnesia.transaction(fn ->
      data = Mnesia.match_object(@hn_data_table, {@hn_data_table, :_, :_, false}, :write)

      Enum.map(data, fn {table, id, uri, _expired_data} ->
        Mnesia.write({table, id, uri, true})
      end)
    end)
  end

  @doc """
  Creates the schema based on its given atom parameter.

  :mnesia -> will create a mnesia schema to save the data and use it as data source

  It's possible to support different types of schemas, if necessary, like ets, for example.
  """
  def create(:mnesia) do
    Mnesia.create_schema([node()])

    Mnesia.start()

    Mnesia.create_table(@hn_data_table,
      attributes: [:id, :fetch_uri, :expired_data],
      type: :ordered_set
    )
  end

  def handle_cast({:save, data}, %{data_source: :mnesia} = state) do
    Mnesia.transaction(fn ->
      Mnesia.clear_table(@hn_data_table)
    end)

    Mnesia.transaction(fn ->
      Enum.map(data, fn item_id ->
        Mnesia.write(
          {@hn_data_table, item_id, "https://hacker-news.firebaseio.com/v0/item/#{item_id}.json?",
           false}
        )
      end)
    end)

    Logger.warn("Records successfully saved to mnesia")

    {:noreply, state}
  end
end
