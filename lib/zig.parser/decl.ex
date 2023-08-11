defmodule Zig.Parser.Decl do
  def post_traverse(rest, [{:Decl, [args]} | rest_args], context, loc, row) do
    {rest, [args | rest_args], context}
  end
end
