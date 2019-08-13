defmodule GraphqlFakerTest do
  use ExUnit.Case
  doctest GraphqlFaker

  test "parses basic query" do
    query = "query Example { hero { name } }"

    assert GraphqlFaker.parse(query) ==
             %{"data" => %{"hero" => %{"name" => "name"}}}
  end

  test "parses query with subquery" do
    query = "query Example { hero { name info { age } } }"
    expected_data = %{"data" => %{"hero" => %{"name" => "name", "info" => %{"age" => "age"}}}}
    assert GraphqlFaker.parse(query) == expected_data
  end

  test "parses query with subquery when subquery is first" do
    query = "query Example { hero { info { age } name } }"
    expected_data = %{"data" => %{"hero" => %{"name" => "name", "info" => %{"age" => "age"}}}}
    assert GraphqlFaker.parse(query) == expected_data
  end

  test "parses query with a list" do
    query = """
    query Example {
      hero {
        age
        friends @plural(count: 2) {
          first_name
          last_name
        }
        superpower
      }
    }
    """

    assert GraphqlFaker.parse(query) ==
             %{
               "data" => %{
                 "hero" => %{
                   "age" => "age",
                   "superpower" => "superpower",
                   "friends" => [
                     %{"first_name" => "first_name-1", "last_name" => "last_name-1"},
                     %{"first_name" => "first_name-2", "last_name" => "last_name-2"}
                   ]
                 }
               }
             }
  end

  test "parses query with nested list" do
    query = """
    query Example {
      x @plural(count: 2) {
        y
        z @plural(count: 2) {
          a
        }
      }
    }
    """

    expected_result = %{
      "data" => %{
        "x" => [
          %{
            "y" => "y-1",
            "z" => [
              %{
                "a" => "a-1-1"
              },
              %{
                "a" => "a-2-1"
              }
            ]
          },
          %{
            "y" => "y-2",
            "z" => [
              %{
                "a" => "a-1-2"
              },
              %{
                "a" => "a-2-2"
              }
            ]
          }
        ]
      }
    }

    assert GraphqlFaker.parse(query) == expected_result
  end
end
