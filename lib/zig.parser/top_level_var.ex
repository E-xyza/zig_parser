defmodule Zig.Parser.TopLevelVar do
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  def post_traverse(rest, [{__MODULE__, [position | args]} | rest_args], context, _, _) do
    {rest, [from_args(args, position) | rest_args], context}
  end

  defp from_args([{:doc_comment, comment} | rest], position) do
    comment_lines =
      comment
      |> String.split("\n")
      |> length

    %{
      from_args(rest, %{position | line: position.line + comment_lines - 1, column: 1})
      | doc_comment: comment
    }
  end

  defp from_args([:extern, form | rest], position) when is_binary(form) do
    %{from_args(rest, position) | extern: form}
  end

  defp from_args([:extern | rest], position) do
    %{from_args(rest, position) | extern: true}
  end

  defp from_args([:export | rest], position) do
    %{from_args(rest, position) | export: true}
  end

  defp from_args([:threadlocal | rest], position) do
    %{from_args(rest, position) | threadlocal: true}
  end

  defp from_args([:var | args], position) do
    Var.from_args(args, position)
  end

  defp from_args([:const | args], position) do
    Const.from_args(args, position)
  end
end
