defmodule Zig.Parser.Union do
  defstruct [:location, :tag, packed: false, extern: false, decls: [], fields: %{}]

  def parse([:LPAREN, tagtype, :RPAREN | rest]), do: %{parse(rest) | tag: tagtype}

  def parse([:LBRACE | rest]), do: do_parse(%__MODULE__{}, rest)

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
