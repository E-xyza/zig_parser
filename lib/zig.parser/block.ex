defmodule Zig.Parser.Block do
  defstruct [:doc_comment, :label, :location, :code]

  alias Zig.Parser

  def post_traverse(rest, [{:Block, code} | rest_args], context, loc, col) do
    block = code
    |> parse
    |> Parser.put_location(loc, col)

    {rest, [block | rest_args], context}
  end

  def post_traverse(rest, [{:BlockExpr, [label, :COLON, code]} | rest_args], context, loc, col) do
    block = code
    |> parse
    |> Parser.put_location(loc, col)
    |> Map.replace!(:label, label)

    {rest, [block | rest_args], context}
  end

  defp parse([:LBRACE | rest]), do: parse(rest, [])

  defp parse([:RBRACE], so_far), do: %__MODULE__{code: Enum.reverse(so_far)}

  defp parse([statement | rest], so_far), do: parse(rest, [statement | so_far])
end
