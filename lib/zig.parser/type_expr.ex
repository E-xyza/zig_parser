defmodule Zig.Parser.TypeExpr do
  @literals Zig.Parser.Collected.literals()

  def post_traverse(rest, [{__MODULE__, [literalterm = {literal, _}]} | rest_args], context, _, _)
      when literal in @literals do
    {rest, [literalterm | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, [:DOT, enum]} | rest_args], context, _, _) do
    {rest, [{:enumliteral, enum} | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, [expr]} | rest_args], context, _, _) do
    {rest, [expr | rest_args], context}
  end
end
