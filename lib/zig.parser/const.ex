defmodule Zig.Parser.Const do
  @enforce_keys [:name, :line, :column]
  defstruct @enforce_keys ++ [:doc_comment, :pub, :type, :value, comptime: false]

  defp decorate(const, [:COLON, type | rest]) do
    decorate(%{const | type: type}, rest)
  end

  defp decorate(const, [:=, value | rest]) do
    decorate(%{const | value: value}, rest)
  end

  defp decorate(const, [:SEMICOLON]), do: const

  def from_args([name | rest], position) do
    decorate(
      %__MODULE__{name: name, line: position.line, column: position.column},
      rest
    )
  end
end
