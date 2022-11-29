defmodule HnAggregator.Model do
  @moduledoc """
  A struct model that will map the data from the data source
  """

  @derive Jason.Encoder

  defstruct [:id, :detail_url, :expired_data]

  @type t :: %__MODULE__{
          id: integer(),
          detail_url: String.t(),
          expired_data: boolean()
        }

  @doc """
  Converts the data to this Model struct based on the data source
  """
  @spec new(atom(), list()) :: list(t())
  def new(data_source, data)

  def new(:mnesia, data) do
    Enum.map(
      data,
      fn
        [id, detail_uri, expired_data] ->
          %__MODULE__{id: id, detail_url: detail_uri, expired_data: expired_data}

        {_, id, detail_uri, expired_data} ->
          %__MODULE__{id: id, detail_url: detail_uri, expired_data: expired_data}
      end
    )
  end
end
