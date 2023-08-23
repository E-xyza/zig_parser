defmodule Zig.Parser.VarDecl do
  alias Zig.Parser
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  def post_traverse(rest, [{:VarDecl, [start, :const | args]} | rest_args], context, _loc, _row) do
    const =
      args
      |> Const.parse()
      |> Parser.put_location(start)

    {rest, [const | rest_args], context}
  end

  def post_traverse(rest, [{:VarDecl, [start, :var | args]} | rest_args], context, _loc, _row) do
    var =
      args
      |> Var.parse()
      |> Parser.put_location(start)

    {rest, [var | rest_args], context}
  end
end
