defmodule Zig.Parser.TopLevelComptime do
  def post_traverse(rest, [{:toplevelcomptime, args} | rest_args], context, _, _) do
    {rest, [{:toplevelcomptime, from_args(args)} | rest_args], context}
  end

  defp from_args([{:doc_comment, comment} | rest]) do
    rest
    |> from_args()
    |> struct(doc_comment: comment)
  end

  defp from_args([:comptime, block]), do: block
end
