defmodule Zig.Parser.PrimaryExpr do
  alias Zig.Parser.Break
  alias Zig.Parser.Continue
  alias Zig.Parser.If

  def post_traverse(rest, [{:PrimaryExpr, args} | args_rest], context, _, _) do
    {rest, [parse(args) | args_rest], context}
  end

  defp parse([:comptime | rest]) do
    %{parse(rest) | comptime: true}
  end

  defp parse([:if | rest]) do
    If.parse(rest)
  end

  defp parse([:break | rest]) do
    Break.parse(rest)
  end

  defp parse([:continue | rest]) do
    Continue.parse(rest)
  end

  defp parse([arg]), do: arg
end
