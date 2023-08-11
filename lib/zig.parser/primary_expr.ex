defmodule Zig.Parser.PrimaryExpr do
  def post_traverse(rest, [{:PrimaryExpr, args} | args_rest], context, _, _) do
    {rest, [parse(args) | args_rest], context}
  end

  defp parse([:comptime | rest]) do
    %{parse(rest) | comptime: true}
  end

  defp parse([arg]), do: arg
end
