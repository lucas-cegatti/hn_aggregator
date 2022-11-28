defmodule HnAggregator.Validator do
  @moduledoc """
  Module responsible to validate types against a given value.

  This module will only implement validations for the specifc HN api, more complex validations should rely on robust libs, like ecto.
  """

  @spec validate_type(any(), atom() | tuple()) :: :ok | {:error, String.t()}
  def validate_type(value, :int) when is_integer(value), do: :ok

  def validate_type(value, {:array, type}) when is_list(value) do
    case Enum.all?(value, &(validate_type(&1, type) == :ok)) do
      true -> :ok
      false -> {:error, "List must contain only #{type}"}
    end
  end

  def validate_type(_value, type), do: {:error, "#{type} not supported or invalid value given"}
end
