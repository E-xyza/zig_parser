defmodule Zig.Parser.TestDecl do
  alias Zig.Parser
  alias Zig.Parser.Block

  defstruct [:position, :doc_comment, :block, :name]

  def post_traverse(
        rest,
        [{:TestDecl, [position, {:doc_comment, comment} | args]} | rest_args],
        context,
        _,
        _
      ) do
    comment_lines =
      comment
      |> String.split("\n")
      |> length

    ast = %{parse(args) | doc_comment: comment, position: position}
    {rest, [ast | rest_args], context}
  end

  def post_traverse(rest, [{:TestDecl, [position | args]} | rest_args], context, _, _) do
    ast = %{parse(args) | position: position}
    {rest, [ast | rest_args], context}
  end

  defp parse([:test, %Block{} = block]) do
    %__MODULE__{block: block}
  end

  defp parse([:test, name, %Block{} = block]) when is_binary(name) do
    %__MODULE__{name: name, block: block}
  end
end
