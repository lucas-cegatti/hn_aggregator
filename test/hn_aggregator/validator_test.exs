defmodule HnAggregator.ValidatorTest do
  alias HnAggregator.Validator
  use ExUnit.Case

  describe "validate_type/2" do
    test "it validates an integer value" do
      assert :ok = Validator.validate_type(2, :int)
    end

    test "it returns error when not an integer type" do
      assert {:error, "int not supported or invalid value given"} =
               Validator.validate_type("2", :int)
    end

    test "it validates a list of integers" do
      assert :ok = Validator.validate_type([1, 2, 3, 4, 5, 6], {:array, :int})
    end

    test "it returns error when a list does not contains only integer types" do
      assert {:error, "List must contain only int"} =
               Validator.validate_type([1, "2", "3", 4, 5, 6], {:array, :int})
    end
  end
end
