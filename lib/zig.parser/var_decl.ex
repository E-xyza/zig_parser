defmodule Zig.Parser.VarDecl do
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  def post_traverse(rest, [{:VarDecl, [:const | args]} | rest_args], context, loc, row) do
    {rest, [Const.parse(args) | rest_args], context}
  end

  def post_traverse(rest, [{:VarDecl, [:var | args]} | rest_args], context, loc, row) do
    {rest, [Var.parse(args) | rest_args], context}
  end
end
