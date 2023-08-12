defmodule Zig.Parser.ContainerDecl do
  alias Zig.Parser
  alias Zig.Parser.Struct

  def post_traverse(rest, [{:ContainerDecl, args} | rest_args], context, loc, row) do
    container = args
    |> parse
    |> Parser.put_location(loc, row)

    {rest, [container | rest_args], context}
  end

  defp parse([:extern | rest]) do
    %{parse(rest) | extern: true}
  end

  defp parse([:packed | rest]) do
    %{parse(rest) | packed: true}
  end

  defp parse([:struct | rest_args]) do
    Struct.parse(rest_args)
  end
end
