defmodule Zig.Parser.ErrorUnionExpr do
  def post_traverse(rest, [{:ErrorUnionExpr, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([identifier]), do: identifier
end
