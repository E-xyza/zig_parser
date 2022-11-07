defmodule Zig.Parser.FnOptions do
  defstruct [
    :position,
    :doc_comment,
    :block,
    :align,
    :linksection,
    :callconv,
    extern: false,
    export: false,
    pub: false,
    inline: :maybe
  ]
end

defmodule Zig.Parser.Function do
  alias Zig.Parser
  alias Zig.Parser.FnOptions

  def post_traverse(rest, [{tag, [position = %{line: _} | args]} | rest_args], context, _, _, tag) do
    fun =
      args
      |> parse([])
      |> Parser.put_opt(:position, position)

    {rest, [fun | rest_args], context}
  end

  defp parse([:export | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:export, true)
  end

  defp parse([:extern, extern_form | rest], parts) when is_binary(extern_form) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:extern, extern_form)
  end

  defp parse([:extern | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:extern, true)
  end

  defp parse([:inline | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:inline, true)
  end

  defp parse([:noinline | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:inline, false)
  end

  # identifiers are required in top level fn declarations.
  defp parse([:fn, name, :LPAREN, _paramdecl, :RPAREN | rest], parts) do
    parse(rest, Keyword.merge(parts, name: name, params: []))
  end

  defp parse([:align, :LPAREN, alignexpr, :RPAREN | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:align, alignexpr)
  end

  defp parse([:linksection, :LPAREN, linkexpr, :RPAREN | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:linksection, linkexpr)
  end

  defp parse([:callconv, :LPAREN, callconv, :RPAREN | rest], parts) do
    rest
    |> parse(parts)
    |> Parser.put_opt(:callconv, callconv)
  end

  defp parse([:SEMICOLON], parts), do: {:fn, %FnOptions{}, parts}

  defp parse([block], parts), do: {:fn, %FnOptions{}, Keyword.merge(parts, block: block)}

  defp parse([expr | rest], parts) do
    parse(rest, Keyword.merge(parts, type: expr))
  end
end
