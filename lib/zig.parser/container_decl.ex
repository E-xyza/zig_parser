defmodule Zig.Parser.ContainerDecl do
  alias Zig.Parser
  alias Zig.Parser.Struct

  def post_traverse(rest, [{:ContainerDecl, [start | args]} | rest_args], context, _, _) do
    container =
      args
      |> parse
      |> Parser.put_location(start)

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

  defp parse([:enum | rest_args]) do
    Zig.Parser.Enum.parse(rest_args)
  end
end
