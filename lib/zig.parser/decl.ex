defmodule Zig.Parser.Decl do
  alias Zig.Parser.Block
  alias Zig.Parser.Const
  alias Zig.Parser.Function
  alias Zig.Parser.Var
  alias Zig.Parser.Usingnamespace

  def post_traverse(rest, [{:Decl, args} | rest_args], context, _loc, _row) do
    {rest, [parse(args) | rest_args], context}
  end

  # decorators

  defp parse([:export | rest]), do: %{parse(rest) | export: true}

  defp parse([:extern, extern | rest]) when is_binary(extern), do: %{parse(rest) | extern: extern}

  defp parse([:extern | rest]), do: %{parse(rest) | extern: true}

  defp parse([:inline | rest]), do: %{parse(rest) | inline: true}

  defp parse([:noinline | rest]), do: %{parse(rest) | inline: false}

  defp parse([:threadlocal | rest]), do: %{parse(rest) | threadlocal: true}

  defp parse([:usingnamespace, payload, :SEMICOLON]) do
    %Usingnamespace{namespace: payload}
  end

  defp parse([%Function{} = function, :SEMICOLON]), do: function

  defp parse([%Function{} = function, %Block{} = block]), do: %{function | block: block}

  defp parse([%Var{} = var]), do: var

  defp parse([%Const{} = const]), do: const
end
