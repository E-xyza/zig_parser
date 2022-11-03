defmodule Zig.Parser.TopLevelVar do
  alias Zig.Parser
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  def post_traverse(
        rest,
        [{__MODULE__, [{:doc_comment, comment}, position | args]} | rest_args],
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
      |> parse
      |> Parser.put_opt(:position, %{
        position
        | line: position.line + comment_lines - 1,
          column: 1
      })
      |> Parser.put_opt(:comment, comment)

    {rest, [ast | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, [position | args]} | rest_args], context, _, _) do
    ast =
      args
      |> parse
      |> Parser.put_opt(:position, position)

    {rest, [ast | rest_args], context}
  end

  defp parse([:extern, form | rest]) when is_binary(form) do
    rest
    |> parse()
    |> Parser.put_opt(:extern, form)
  end

  defp parse([:extern | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:extern, true)
  end

  defp parse([:export | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:export, true)
  end

  defp parse([:threadlocal | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:threadlocal, true)
  end

  defp parse([:var | args]) do
    Var.from_args(args)
  end

  defp parse([:const | args]) do
    Const.from_args(args)
  end
end
