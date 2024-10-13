defmodule Project73.Utils.ValidatedStructTest do
  use ExUnit.Case
  use Project73.Utils.ValidatedStruct

  validated_struct TestStruct do
    field :name
    field :age, :integer, lt: 100
    field :city, :string, default: "New York"
  end

  describe "Generating struct" do
    test "generates a struct with the given fields" do
      test_struct = %TestStruct{
        name: "John",
        age: 30,
        city: "Washington"
      }

      assert test_struct.__struct__ == TestStruct
    end

    test "sets default values for fields" do
      test_struct = %TestStruct{
        name: "John",
        age: 30
      }

      assert test_struct.city == "New York"
    end
  end

  describe "Validating struct" do
    test "validate function generated" do
      assert Kernel.function_exported?(TestStruct, :validate, 1)
    end

    test "returns {:ok, struct} if struct is valid" do
      assert {:ok, %TestStruct{name: "John", age: 30, city: "New York"}} =
               TestStruct.validate(%TestStruct{name: "John", age: 30})
    end

    test "should riss an error if invalid type is passed" do
      assert_raise FunctionClauseError, fn ->
        TestStruct.validate("")
      end
    end

    test "should validate if field has correct type" do
      assert {:error, {:field, :city, [:not_a_string]}} =
               TestStruct.validate(%TestStruct{city: 1, name: "John", age: 30})
    end
  end
end
