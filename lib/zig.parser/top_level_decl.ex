defmodule Zig.Parser.TopLevelDecl do
  def post_traverse(rest, [{__MODULE__, args} | rest_args], context, _, _) do
    {rest, [from_args(args) | rest_args], context}
  end

  defp from_args([{:doc_comment, comment} | rest]) do
    rest
    |> from_args()
    |> struct(doc_comment: comment)
  end

  defp from_args([:comptime | rest]) do
    rest
    |> from_args()
    |> struct(comptime: true)
  end

  defp from_args([:pub | rest]) do
    rest
    |> from_args()
    |> struct(pub: true)
  end

  defp from_args([base]), do: base
end
