defmodule Zig.Parser.Block do
  defstruct [:doc_comment, :name, :label, code: []]

  def post_traverse(rest, [{__MODULE__, block_parts} | rest_args], context, _, _) do
    {rest, [parse_block(block_parts) | rest_args], context}
  end

  defp parse_block([:LBRACE | rest]), do: parse_block(rest, [])

  defp parse_block([:RBRACE], so_far), do: %__MODULE__{code: Enum.reverse(so_far)}

  defp parse_block([statement | rest], so_far), do: parse_block(rest, [statement | so_far])
end

defmodule Zig.Parser.BlockExpr do
  alias Zig.Parser.Block

  def post_traverse(rest, [{__MODULE__, block_args} | rest_args], context, _, _) do
    {rest, [parse_block(block_args) | rest_args], context}
  end

  defp parse_block([tag, :COLON, block = %Block{}]) do
    Map.put(block, :label, tag)
  end

  defp parse_block([block]), do: block
end
