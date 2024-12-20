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
      assert {:error, [{{:city}, [:not_a_string]}]} =
               TestStruct.validate(%TestStruct{city: 1, name: "John", age: 30})
    end
  end

  validated_struct ComplexTestStruct do
    field :str_optional, :string, optional: true
    field :str_max_length, :string, max_length: 5
    field :str_min_length, :string, min_length: 5
    field :str_not_empty, :string, not_empty: true
    field :list_max_length, {:list, :string}, max_length: 3
    field :list_min_length, {:list, :string}, min_length: 3
    field :list_not_empty, {:list, :string}, not_empty: true
    field :int_gt, :integer, gt: 10
    field :float_lt, :float, lt: 10.0
    field :float_gte, :float, gte: 10.0
    field :int_lte, :integer, lte: 10
    field :int_eq, :integer, eq: 10
    field :int_neq, :integer, neq: 10
  end

  describe "Validating struct with complex validations" do
    test "should require non-optional fields" do
      assert {:error,
              [
                {{:str_max_length}, [:missing_field]},
                {{:str_min_length}, [:missing_field]}
                | _
              ]} =
               ComplexTestStruct.validate(%ComplexTestStruct{})
    end

    test "should fail all validations" do
      assert {:error,
              [
                {{:str_max_length}, [{:max_length_exceeded, 5}]},
                {{:str_min_length}, [{:min_length_not_reached, 5}]},
                {{:str_not_empty}, [:empty]},
                {{:list_max_length}, [{:max_length_exceeded, 3}]},
                {{:list_min_length}, [{:min_length_not_reached, 3}]},
                {{:list_not_empty}, [:empty]},
                {{:int_gt}, [{:less_than_min, 10}]},
                {{:float_lt}, [{:greater_than_max, 10.0}]},
                {{:float_gte}, [{:less_than_min, 10.0}]},
                {{:int_lte}, [{:greater_than_max, 10}]},
                {{:int_eq}, [{:not_equal, 5}]},
                {{:int_neq}, [{:equal, 10}]}
              ]} =
               ComplexTestStruct.validate(%ComplexTestStruct{
                 str_max_length: "123456",
                 str_min_length: "1234",
                 str_not_empty: "",
                 list_max_length: ["1", "2", "3", "4"],
                 list_min_length: ["1", "2"],
                 list_not_empty: [],
                 int_gt: 5,
                 float_lt: 15.0,
                 float_gte: 5.0,
                 int_lte: 15,
                 int_eq: 5,
                 int_neq: 10
               })
    end

    test "should pass all validations" do
      struct = %ComplexTestStruct{
        str_max_length: "12345",
        str_min_length: "12345",
        str_not_empty: "not empty",
        list_max_length: ["1", "2", "3"],
        list_min_length: ["1", "2", "3"],
        list_not_empty: ["not empty"],
        int_gt: 15,
        float_lt: 5.0,
        float_gte: 10.0,
        int_lte: 5,
        int_eq: 10,
        int_neq: 5
      }

      assert {:ok, ^struct} =
               ComplexTestStruct.validate(struct)
    end
  end

  validated_struct do
    field :name
    field :age, :integer, lt: 100
    field :city, :string, default: "New York"
  end

  describe "ValidatedStruct without a name" do
    test "should generate a struct with the given fields" do
      struct = %__MODULE__{
        name: "John",
        age: 30,
        city: "Washington"
      }

      assert struct.__struct__ == __MODULE__
    end
  end

  validated_struct Address do
    field :country, :string, not_empty: true
    field :city, :string, not_empty: true
    field :postal_code, :string, not_empty: true
    field :line1, :string, not_empty: true
    field :line2, :string, optional: true
  end

  validated_struct Update do
    field :first_name, :string, not_empty: true
    field :last_name, :string, not_empty: true
    field :address, Project73.Utils.ValidatedStructTest.Address.t(), dive: true
  end

  describe "Validating nested structs" do
    test "should validate nested structs" do
      assert {:error,
              [
                {{:first_name}, [:empty]},
                {{:address, :country}, [:missing_field]},
                {{:address, :city}, [:empty]},
                {{:address, :postal_code}, [:missing_field]},
                {{:address, :line1}, [:missing_field]}
              ]} =
               Update.validate(%Update{
                 first_name: "",
                 last_name: "Doe",
                 address: %Address{city: ""}
               })
    end
  end
end
