defmodule Zig.Parser.Statement do
  alias Zig.Parser.Block

  def post_traverse(rest, [{:Statement, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([:comptime | rest_args]) do
    %{parse(rest_args) | comptime: true}
  end

  defp parse([:nosuspend | rest_args]) do
    case parse(rest_args) do
      %Block{} = block ->
        %{block | nosuspend: true}

      other ->
        {:nosuspend, other}
    end
  end

  defp parse([:suspend | rest_args]) do
    case parse(rest_args) do
      %Block{} = block ->
        %{block | suspend: true}

      other ->
        {:suspend, other}
    end
  end

  defp parse([:defer | rest_args]) do
    {:defer, parse(rest_args)}
  end

  defp parse([:errdefer, :|, capture, :| | rest_args]) do
    {:errdefer, capture, parse(rest_args)}
  end

  defp parse([:errdefer | rest_args]) do
    {:errdefer, parse(rest_args)}
  end

  defp parse([statement, :SEMICOLON]), do: statement

  defp parse([content]), do: content
end
