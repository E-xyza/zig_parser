defmodule Zig.Parser.Const do
  @enforce_keys [:name, :line, :column]
  defstruct @enforce_keys ++ [:doc_comment, :pub, :type, :value, comptime: false]

  def from_args([name | rest], position) when is_binary(name) do
    decorate(
      %__MODULE__{name: String.to_atom(name), line: position.line, column: position.column},
      rest
    )
  end

  defp decorate(const, [:COLON, type | rest]) do
    decorate(%{const | type: type}, rest)
  end

  defp decorate(const, [:=, value | rest]) do
    decorate(%{const | value: value}, rest)
  end

  defp decorate(const, [:SEMICOLON]), do: const
end
