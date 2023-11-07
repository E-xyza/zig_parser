defmodule Zig.Parser.Struct do
  defstruct [:location, :backed, packed: false, extern: false, decls: [], fields: %{}]

  def parse([:LPAREN, backing, :RPAREN | rest]), do: %{parse(rest) | backed: backing}

  def parse([:LBRACE | rest]), do: do_parse(%__MODULE__{}, rest)

  defp do_parse(struct, [name, :COLON, type, :=, value | rest]) do
    struct
    |> Map.update!(:fields, &Map.put(&1, name, {type, value}))
    |> do_parse(rest)
  end

  defp do_parse(struct, [name, :COLON, type, :COMMA | rest]) do
    struct
    |> Map.update!(:fields, &Map.put(&1, name, type))
    |> do_parse(rest)
  end

  defp do_parse(struct, [name, :COLON, type | rest]) do
    struct
    |> Map.update!(:fields, &Map.put(&1, name, type))
    |> do_parse(rest)
  end

  defp do_parse(struct, [:RBRACE]) do
    Map.update!(struct, :decls, &Enum.reverse/1)
  end

  defp do_parse(struct, [decl | rest]) do
    struct
    |> Map.update!(:decls, &[decl | &1])
    |> do_parse(rest)
  end
end
