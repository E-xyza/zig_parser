defmodule Zig.Parser.TopLevelComptime do
  alias Zig.Parser

  def post_traverse(rest, [{:toplevelcomptime, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([{:doc_comment, comment} | rest]) do
    {:comptime, _, block} = parse(rest)
    {:comptime, %{}, Parser.put_opt(block, :doc_comment, comment)}
  end

  defp parse([:comptime, block]), do: {:comptime, %{}, block}
end
