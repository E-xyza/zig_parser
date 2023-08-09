defmodule Zig.Parser.Comptime do
  defstruct [:block, :doc_comment, :context]
end

defmodule Zig.Parser.TopLevelComptime do
  alias Zig.Parser
  alias Zig.Parser.Comptime

  def post_traverse(rest, [{:toplevelcomptime, args} | rest_args], context, _, _) do
    {rest, [parse(args, context) | rest_args], context}
  end

  defp parse(args, context) do
    args
    |> parse
    |> Parser.put_context(context)
  end

  defp parse([{:doc_comment, comment} | rest]) do
    rest
    |> parse
    |> Map.update!(:doc_comment, comment)
  end

  defp parse([:comptime, block]), do: %Comptime{block: block}
end
