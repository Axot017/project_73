defmodule Project73.Utils.ValidatedStructTest do
  use ExUnit.Case
  use Project73.Utils.ValidatedStruct

  validated_struct TestStruct do
    field :name
    field :age, :integer
    field :email, String.t()
  end

  describe "Generating struct" do
    test "generates a struct with the given fields" do
      test_struct = %TestStruct{
        name: "John",
        age: 30,
        email: "test@email.com"
      }

      assert test_struct.__struct__ == TestStruct
    end
  end
end
