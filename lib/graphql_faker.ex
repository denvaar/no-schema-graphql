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
    fields =
      selections
      |> Enum.reduce(%{}, fn selection, a -> Map.merge(a, build(selection)) end)

    children =
      for n <- 1..count do
        for {k, v} <- Map.to_list(fields) do
          {k, pluralize(v, n)}
        end
        |> Map.new()
      end

    %{name => children}
  end

  def build(%Field{name: name, selection_set: %SelectionSet{selections: selections}}) do
    children =
      selections
      |> Enum.reduce(%{}, fn selection, a -> Map.merge(a, build(selection)) end)

    %{name => children}
  end

  def pluralize(value, index) when is_binary(value) do
    "#{value}-#{index}"
  end

  def pluralize(fields, index) when is_list(fields) do
    fields
    |> Enum.map(fn field ->
      field
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {k, "#{pluralize(v, index)}"} end)
      |> Map.new()
    end)
  end
end
