defmodule Zig.Parser.Statement do
  def post_traverse(rest, [{:Statement, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([:comptime | rest_args]) do
    %{parse(rest_args) | comptime: true}
  end

  defp parse([content]), do: content
end
