defmodule Zig.Parser.ParamDecl do
  alias Zig.Parser

  def post_traverse(rest, [{:ParamDecl, args}], context, _, _) do
    {rest, [parse(args)], context}
  end

  defp parse([identifier, :COLON, type]) do
    {identifier, type}
  end

  defp parse([:comptime, identifier]) do
    {:comptime, identifier}
  end

  defp parse([:noalias, identifier]) do
    {:noalias, identifier}
  end

  defp parse([:...]), do: :...

  defp parse([type]), do: type
end
