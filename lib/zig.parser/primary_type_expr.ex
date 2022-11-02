defmodule Zig.Parser.StructOptions do
  defstruct extern: false, packed: false, comment: nil
end

defmodule Zig.Parser.OpaqueOptions do
  defstruct extern: false, packed: false, comment: nil
end

defmodule Zig.Parser.EnumOptions do
  defstruct extern: false, packed: false, comment: nil, type: nil
end

defmodule Zig.Parser.UnionOptions do
  defstruct [extern: false, packed: false, comment: nil, tagtype: nil, tagged: false]
end

defmodule Zig.Parser.PrimaryTypeExpr do
  alias Zig.Parser.EnumOptions
  alias Zig.Parser.OpaqueOptions
  alias Zig.Parser.StructOptions
  alias Zig.Parser.UnionOptions

  def post_traverse(rest, [{:PrimaryTypeExpr, args} | args_rest], context, _, _) do
    {rest, [parse(args) | args_rest], context}
  end

  defp parse([{:builtin, name}, :LPAREN | builtin_args]) do
    {:builtin, name, parse_builtin(builtin_args, [])}
  end

  @containers ~w(struct opaque enum union)a
  @container_opts %{struct: %StructOptions{}, opaque: %OpaqueOptions{}, enum: %EnumOptions{}, union: %UnionOptions{}}

  defp parse([:DOT, enum_literal]) do
    {:enum_literal, enum_literal}
  end

  defp parse([:extern | rest]) do
    {container, container_opts, container_code} = parse(rest)
    {container, %{container_opts | extern: true}, container_code}
  end

  defp parse([:packed | rest]) do
    {container, container_opts, container_code} = parse(rest)
    {container, %{container_opts | packed: true}, container_code}
  end

  defp parse([:enum, :LPAREN, expr, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:enum, :LBRACE | rest])
    {container, %{container_opts | type: expr}, container_code}
  end

  defp parse([:union, :LPAREN, :enum, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:union, :LBRACE | rest])
    {container, %{container_opts | tagged: true}, container_code}
  end

  defp parse([:union, :LPAREN, :enum, :LPAREN, enumtype, :RPAREN, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:union, :LBRACE | rest])
    {container, %{container_opts | tagtype: {:enum, enumtype}, tagged: true}, container_code}
  end

  defp parse([:union, :LPAREN, expr, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:union, :LBRACE | rest])
    {container, %{container_opts | tagtype: expr, tagged: true}, container_code}
  end

  defp parse([container, :LBRACE | container_args]) when container in @containers do
    opts = @container_opts[container]

    {opts, rest_args} =
      case container_args do
        [{:container_doc_comment, [comment]} | rest_args] ->
          comment =
            comment
            |> String.split("\n")
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.trim_leading(&1, "//!"))
            |> Enum.join("\n")

          {Map.put(opts, :comment, comment), rest_args}

        rest_args ->
          {opts, rest_args}
      end

    {container, opts, parse_container_args(rest_args, [])}
  end

  defp parse(["'", parsed_char, "'"]), do: parsed_char

  defp parse([any]), do: any

  defp parse_builtin([:RPAREN], so_far), do: Enum.reverse(so_far)
  defp parse_builtin([:COMMA | rest], so_far), do: parse_builtin(rest, so_far)
  defp parse_builtin([value | rest], so_far), do: parse_builtin(rest, [value | so_far])

  defp parse_container_args([:RBRACE], so_far), do: Enum.reverse(so_far)
end
