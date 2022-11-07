defmodule Zig.Parser.TestOptions do
  defstruct [:position, :doc_comment]
end

defmodule Zig.Parser.TestDecl do
  alias Zig.Parser
  alias Zig.Parser.TestOptions

  def post_traverse(
        rest,
        [{__MODULE__, [position, {:doc_comment, comment} | args]} | rest_args],
        context,
        _,
        _
      ) do
    comment_lines =
      comment
      |> String.split("\n")
      |> length

    ast =
      args
      |> parse()
      |> Parser.put_opt(:doc_comment, comment)
      |> Parser.put_opt(:position, %{
        position
        | line: position.line + comment_lines - 1,
          column: 1
      })

    {rest, [ast | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, [position | args]} | rest_args], context, _, _) do
    ast =
      args
      |> parse
      |> Parser.put_opt(:position, position)

    {rest, [ast | rest_args], context}
  end

  defp parse([:test, block = {:block, _, _}]) do
    {:test, %TestOptions{}, {nil, block}}
  end

  defp parse([:test, name, block = {:block, _, _}]) when is_binary(name) do
    {:test, %TestOptions{}, {name, block}}
  end
end
