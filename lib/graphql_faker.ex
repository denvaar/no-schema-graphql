defmodule GraphqlFaker do
  alias Absinthe.Language.{
    Argument,
    IntValue,
    Directive,
    OperationDefinition,
    SelectionSet,
    Field
  }

  def parse(input) do
    {:ok, %{input: document}} = Absinthe.Phase.Parse.run(input)

    document.definitions
    |> List.first()
    |> build()
  end

  def build(%OperationDefinition{selection_set: %SelectionSet{selections: selections}}) do
    data =
      selections
      |> Enum.reduce(%{}, fn selection, a -> Map.merge(a, build(selection)) end)

    %{"data" => data}
  end

  def build(%Field{name: name, selection_set: nil}) do
    %{name => name}
  end

  def build(%Field{
        name: name,
        selection_set: %SelectionSet{selections: selections},
        directives: [
          %Directive{
            name: "plural",
            arguments: [%Argument{name: "count", value: %IntValue{value: count}} | _]
          }
          | _
        ]
      }) do
    children =
      for n <- 1..count,
          s <- selections do
        [{k, v}] = Enum.to_list(build(s))

        %{k => "#{v}-#{n}"}
      end

    %{name => children}
  end

  def build(%Field{name: name, selection_set: %SelectionSet{selections: selections}}) do
    children =
      selections
      |> Enum.reduce(%{}, fn selection, a -> Map.merge(a, build(selection)) end)

    %{name => children}
  end
end
