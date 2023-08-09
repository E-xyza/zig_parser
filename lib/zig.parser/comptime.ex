defmodule Zig.Parser.Comptime do
  alias Zig.Parser
  alias Zig.Parser.Comptime

  def post_traverse(rest, [{:ComptimeDecl, [:comptime, content]} | rest_args], context, loc, row) do
    updated_content = content
    |> Parser.put_location(loc, row)
    |> Map.replace!(:comptime, true)

    {rest, [updated_content | rest_args], context}
  end

  defp parse(args, context) do
    args
    |> parse
    |> dbg(limit: 25)
    |> Parser.put_context(context)
  end

  defp parse([{:doc_comment, comment} | rest]) do
    rest
    |> parse
    |> Map.update!(:doc_comment, comment)
  end

  defp parse([:comptime, block]), do: Map.replace!()
end
