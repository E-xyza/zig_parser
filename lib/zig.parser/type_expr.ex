defmodule Zig.Parser.TypeExpr do
  @literals Zig.Parser.Collected.literals()

  alias Zig.Parser.Array
  alias Zig.Parser.Pointer

  def post_traverse(rest, [{:TypeExpr, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([literalterm = {literal, _}]) when literal in @literals, do: literalterm
  defp parse([:DOT, enum]), do: {:enumliteral, enum}
  defp parse([:LBRACKET, :RBRACKET | _] = slice), do: Pointer.parse(slice)
  defp parse([:LBRACKET, :COLON | _] = slice), do: Pointer.parse(slice)
  defp parse([:LBRACKET, :* | _] = manyptr), do: Pointer.parse(manyptr)
  defp parse([:LBRACKET | _] = array), do: Array.parse(array)
  defp parse([:* | _] = pointer), do: Pointer.parse(pointer)
  defp parse([:** | rest]), do: %Pointer{count: :one, type: parse([:* | rest])}
  defp parse([:QUESTIONMARK | rest]), do: {:optional, parse(rest)}
  defp parse([:anyframe, :MINUSRARROW | rest]), do: {:anyframe, parse(rest)}
  defp parse([singleton]), do: singleton
end
