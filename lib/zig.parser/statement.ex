defmodule Zig.Parser.Statement do
  def post_traverse(rest, [{:Statement, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([:comptime | rest_args]) do
    %{parse(rest_args) | comptime: true}
  end

  defp parse([:nosuspend | rest_args]) do
    %{parse(rest_args) | nosuspend: true}
  end

  defp parse([:suspend | rest_args]) do
    %{parse(rest_args) | suspend: true}
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

  defp parse([content]), do: content
end
