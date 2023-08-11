defmodule Zig.Parser.Decl do
  alias Zig.Parser.Function
  alias Zig.Parser.Block

  def post_traverse(rest, [{:Decl, args} | rest_args], context, _loc, _row) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([:export | rest]) do
    %{parse(rest) | export: true}
  end

  defp parse([:extern, extern | rest]) when is_binary(extern) do
    %{parse(rest) | extern: extern}
  end

  defp parse([:extern | rest]), do: %{parse(rest) | extern: true}

  defp parse([:inline | rest]), do: %{parse(rest) | inline: true}

  defp parse([:noinline | rest]), do: %{parse(rest) | inline: false}

  defp parse([%Function{} = function, :SEMICOLON]), do: function

  defp parse([%Function{} = function, %Block{} = block]), do: %{function | block: block}
end
