defmodule Zig.Parser.ContainerDeclarations do
  def post_traverse(rest, [{:ContainerDeclarations, []} | rest_args], context, _loc, _row) do
    {rest, rest_args, context}
  end

  def post_traverse(rest, [{:ContainerDeclarations, args} | rest_args], context, _loc, _row) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([:comptime | rest]) do
    %{parse(rest) | comptime: true}
  end

  defp parse([{:doc_comment, comment} | rest]) do
    %{parse(rest) | doc_comment: comment}
  end

  defp parse([:pub | rest]) do
    %{parse(rest) | pub: true}
  end

  defp parse([rest]), do: rest
end
