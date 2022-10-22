defmodule Zig.Parser.TestDecl do
  @enforce_keys [:line, :column]
  defstruct @enforce_keys ++ [:name, :doc_comment, :block]

  alias Zig.Parser.Block

  def post_traverse(rest, [{__MODULE__, [position | args]} | rest_args], context, _, _) do
    {rest, [from_args(args, position) | rest_args], context}
  end

  defp from_args([:test, block = %Block{}], position) do
    %__MODULE__{line: position.line, column: position.column, block: block}
  end

  defp from_args([:test, name, block = %Block{}], position) when is_binary(name) do
    %__MODULE__{line: position.line, column: position.column, block: block, name: name}
  end

  defp from_args([{:doc_comment, comment} | rest], position) do
    comment_lines =
      comment
      |> String.split("\n")
      |> length

    rest
    |> from_args(%{position | line: position.line + comment_lines - 1, column: 1})
    |> Map.put(:doc_comment, comment)
  end
end
