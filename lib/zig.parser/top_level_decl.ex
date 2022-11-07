defmodule Zig.Parser.TopLevelDecl do
  alias Zig.Parser

  def post_traverse(rest, [{__MODULE__, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([{:doc_comment, comment} | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:doc_comment, comment)
  end

  defp parse([:comptime | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:comptime, true)
  end

  defp parse([:pub | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:pub, true)
  end

  defp parse([base]), do: base
end
