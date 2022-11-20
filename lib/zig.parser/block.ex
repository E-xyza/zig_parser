defmodule Zig.Parser.BlockOptions do
  defstruct [:doc_comment, :label, :position]
end

defmodule Zig.Parser.Block do
  alias Zig.Parser.BlockOptions

  def post_traverse(rest, [{__MODULE__, block_parts} | rest_args], context, _, _) do
    {rest, [parse(block_parts) | rest_args], context}
  end

  defp parse([:LBRACE | rest]), do: parse(rest, [])

  defp parse([:RBRACE], so_far), do: {:block, %BlockOptions{}, Enum.reverse(so_far)}

  defp parse([statement | rest], so_far), do: parse(rest, [statement | so_far])
end

defmodule Zig.Parser.BlockExpr do
  alias Zig.Parser

  def post_traverse(rest, [{__MODULE__, block_args} | rest_args], context, _, _) do
    {rest, [parse(block_args) | rest_args], context}
  end

  defp parse([tag, :COLON, block]) do
    Parser.put_opt(block, :label, tag)
  end

  defp parse([block]), do: block
end
