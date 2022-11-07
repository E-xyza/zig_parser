defmodule Zig.Parser.ParamDeclOption do
  defstruct [:doc_comment, noalias: false, comptime: false]
end

defmodule Zig.Parser.ParamDecl do
  alias Zig.Parser
  alias Zig.Parser.ParamDeclOption

  def post_traverse(rest, [{__MODULE__, args}], context, _, _) do
    {rest, [parse(args)], context}
  end

  defp parse([{:doc_comment, comment} | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:doc_comment, comment)
  end

  defp parse([:noalias | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:noalias, true)
  end

  defp parse([:comptime | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:comptime, true)
  end

  defp parse([identifier, :COLON, type]) do
    {identifier, %ParamDeclOption{}, type}
  end

  defp parse([:...]), do: :...

  defp parse([type]) do
    {:_, %ParamDeclOption{}, type}
  end
end
