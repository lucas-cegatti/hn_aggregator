defmodule HnAggregator.Schema do
  @moduledoc """
  Schema that stores the HN data into memory
  """
  use GenServer

  alias :mnesia, as: Mnesia

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    create(:mnesia)

    {:ok, args}
  end

  def create(:mnesia) do
    Mnesia.create_schema([node()])

    Mnesia.start()

    Mnesia.create_table(HnData, attributes: [:id, :fetch_uri], type: :ordered_set)
  end
end
