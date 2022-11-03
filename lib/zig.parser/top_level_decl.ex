defmodule Zig.Parser.TopLevelDecl do
  alias Zig.Parser

  def post_traverse(rest, [{__MODULE__, args} | rest_args], context, _, _) do
    {rest, [from_args(args) | rest_args], context}
  end

  defp from_args([{:doc_comment, comment} | rest]) do
    rest
    |> from_args()
    |> Parser.put_opt(:comment, comment)
  end

  defp from_args([:comptime | rest]) do
    rest
    |> from_args()
    |> Parser.put_opt(:comptime, true)
  end

  defp from_args([:pub | rest]) do
    rest
    |> from_args()
    |> Parser.put_opt(:pub, true)
  end

  defp from_args([base]), do: base
end
