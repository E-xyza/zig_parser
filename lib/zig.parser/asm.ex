defmodule Zig.Parser.Asm do
  alias Zig.Parser

  defstruct [:location, :code, outputs: [], inputs: [], clobbers: [], volatile: false]

  def post_traverse(
        rest,
        [{:AsmExpr, [:asm | args]} | args_rest],
        context,
        loc,
        col
      ) do
    asm =
      args
      |> parse(%__MODULE__{})
      |> Parser.put_location(loc, col)

    {rest, [asm | args_rest], context}
  end

  defp parse([:volatile | rest], asm) do
    parse(rest, %{asm | volatile: true})
  end

  defp parse([:LPAREN, {:string, code}, :COLON | rest], asm) do
    parse(rest, %{asm | code: code})
  end

  defp parse([{:AsmOutputList, outputs}, :COLON | rest], asm) do
    parse(rest, %{asm | outputs: parse_io(outputs, [])})
  end

  defp parse([{:AsmInputList, inputs}, :COLON | rest], asm) do
    parse(rest, %{asm | inputs: parse_io(inputs, [])})
  end

  defp parse([{:StringList, clobbers}, :RPAREN], asm) do
    clobber_names = Enum.map(clobbers, fn {:string, string} -> string end)
    %{asm | clobbers: clobber_names}
  end

  defp parse([:RPAREN], asm), do: asm

  defp parse_io(
         [
           :LBRACKET,
           id,
           :RBRACKET,
           {:string, assign},
           :LPAREN,
           :MINUSRARROW,
           type,
           :RPAREN | rest
         ],
         so_far
       ) do
    parse_io(rest, [{id, assign, type: type} | so_far])
  end

  defp parse_io(
         [:LBRACKET, id, :RBRACKET, {:string, assign}, :LPAREN, identifier, :RPAREN | rest],
         so_far
       ) do
    parse_io(rest, [{id, assign, var: identifier} | so_far])
  end

  defp parse_io([:COMMA | rest], so_far) do
    parse_io(rest, so_far)
  end

  defp parse_io([], so_far), do: Enum.reverse(so_far)
end
