defmodule Zig.Parser.Function do
  @enforce_keys [:line, :column]
  defstruct @enforce_keys ++
              [
                :name,
                :params,
                :type,
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

  alias Zig.Parser.Block
  alias Zig.Parser.TypeExpr

  def post_traverse(rest, [{tag, [position = %{line: _} | args]} | rest_args], context, _, _, tag) do
    {rest,
     [from_args(args, %__MODULE__{line: position.line, column: position.column}) | rest_args],
     context}
  end

  defp from_args([:export | rest], function) do
    rest
    |> from_args(function)
    |> struct(export: true)
  end

  defp from_args([:extern, extern_form | rest], function) when is_binary(extern_form) do
    rest
    |> from_args(function)
    |> struct(extern: extern_form)
  end

  defp from_args([:extern | rest], function) do
    rest
    |> from_args(function)
    |> struct(extern: true)
  end

  defp from_args([:inline | rest], function) do
    rest
    |> from_args(function)
    |> struct(inline: true)
  end

  defp from_args([:noinline | rest], function) do
    rest
    |> from_args(function)
    |> struct(inline: false)
  end

  # identifiers are required in top level fn declarations.
  defp from_args([:fn, identifier, :LPAREN, _paramdecl, :RPAREN | rest], function) do
    from_args(rest, Map.merge(function, %{name: String.to_atom(identifier), params: []}))
  end

  defp from_args([:align, :LPAREN, alignexpr, :RPAREN | rest], function) do
    rest
    |> from_args(function)
    |> struct(align: alignexpr)
  end

  defp from_args([:linksection, :LPAREN, linkexpr, :RPAREN | rest], function) do
    rest
    |> from_args(function)
    |> struct(linksection: linkexpr)
  end

  defp from_args([:callconv, :LPAREN, callconv, :RPAREN | rest], function) do
    rest
    |> from_args(function)
    |> struct(callconv: callconv)
  end

  defp from_args([typeexpr = %TypeExpr{} | rest], function) do
    rest
    |> from_args(function)
    |> struct(type: typeexpr)
  end

  defp from_args([:SEMICOLON], function), do: function

  defp from_args([block = %Block{}], function), do: struct(function, block: block)
end
