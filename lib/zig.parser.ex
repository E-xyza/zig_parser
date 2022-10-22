defmodule Zig.Parser do
  defstruct [
    :doc_comment,
    tests: [],
    functions: [],
    usingnamespace: [],
    decls: [],
    toplevelcomptime: []
  ]

  require Pegasus
  import NimbleParsec

  alias Zig.Parser.Asm
  alias Zig.Parser.Block
  alias Zig.Parser.Const
  alias Zig.Parser.Collected
  alias Zig.Parser.Expr
  alias Zig.Parser.InitList
  alias Zig.Parser.TestDecl
  alias Zig.Parser.TopLevelComptime
  alias Zig.Parser.TopLevelDecl
  alias Zig.Parser.Function
  alias Zig.Parser.TopLevelFn
  alias Zig.Parser.TopLevelVar
  alias Zig.Parser.TypeExpr
  alias Zig.Parser.Usingnamespace
  alias Zig.Parser.Var
  alias Zig.Parser.ParamDecl

  @keywords ~w(align allowzero and anyframe anytype asm async await break callconv catch comptime const continue defer else enum errdefer error export extern fn for if inline noalias nosuspend noinline opaque or orelse packed pub resume return linksection struct suspend switch test threadlocal try union unreachable usingnamespace var volatile while)a
  @keyword_mapping Enum.map(@keywords, &{:"KEYWORD_#{&1}", [token: &1]})

  @operators ~w(AMPERSAND AMPERSANDEQUAL ASTERISK ASTERISK2 ASTERISKEQUAL ASTERISKPERCENT ASTERISKPERCENTEQUAL CARET CARETEQUAL COLON COMMA DOT DOT2 DOT3 DOTASTERISK DOTQUESTIONMARK EQUAL EQUALEQUAL EQUALRARROW EXCLAMATIONMARK EXCLAMATIONMARKEQUAL LARROW LARROW2 LARROW2EQUAL LARROWEQUAL LBRACE LBRACKET LPAREN MINUS MINUSEQUAL MINUSPERCENT MINUSPERCENTEQUAL MINUSRARROW PERCENT PERCENTEQUAL PIPE PIPE2 PIPEEQUAL PLUS PLUS2 PLUSEQUAL PLUSPERCENT PLUSPERCENTEQUAL LETTERC QUESTIONMARK RARROW RARROW2 RARROW2EQUAL RARROWEQUAL RBRACE RBRACKET RPAREN SEMICOLON SLASH SLASHEQUAL TILDE)a
  @operator_mapping Enum.map(@operators, &{&1, [token: true]})

  @collecteds ~w(IDENTIFIER INTEGER CHAR_LITERAL FLOAT INTEGER STRINGLITERAL)a
  @collected_mapping Enum.map(
                       @collecteds,
                       &{&1, [collect: true, post_traverse: {Collected, :post_traverse, [&1]}]}
                     )

  @parser_options [
                    container_doc_comment: [
                      post_traverse: :container_doc_comment,
                      tag: true,
                      collect: true
                    ],
                    doc_comment: [post_traverse: :doc_comment, tag: true, collect: true],
                    TestDecl: [
                      tag: TestDecl,
                      start_position: true,
                      post_traverse: {TestDecl, :post_traverse, []}
                    ],
                    skip: [ignore: true],
                    STRINGLITERALSINGLE: [
                      tag: true,
                      post_traverse: :string_literal_single,
                      collect: true
                    ],
                    TopLevelComptime: [
                      tag: :toplevelcomptime,
                      post_traverse: {TopLevelComptime, :post_traverse, []}
                    ],
                    TopLevelDecl: [
                      tag: TopLevelDecl,
                      post_traverse: {TopLevelDecl, :post_traverse, []}
                    ],
                    TopLevelVar: [
                      tag: TopLevelVar,
                      start_position: true,
                      post_traverse: {TopLevelVar, :post_traverse, []}
                    ],
                    TopLevelFn: [
                      tag: TopLevelFn,
                      start_position: true,
                      post_traverse: {Function, :post_traverse, [TopLevelFn]}
                    ],
                    TypeExpr: [
                      tag: TypeExpr,
                      post_traverse: {TypeExpr, :post_traverse, []}
                    ],
                    Expr: [
                      tag: Expr,
                      post_traverse: {Expr, :post_traverse, []}
                    ],
                    InitList: [
                      tag: InitList,
                      post_traverse: {InitList, :post_traverse, []}
                    ],
                    Usingnamespace: [
                      tag: :usingnamespace,
                      post_traverse: {Usingnamespace, :post_traverse, []}
                    ],
                    ParamDeclList: [tag: true],
                    ParamDecl: [tag: ParamDecl],
                    AsmExpr: [tag: Asm, post_traverse: {Asm, :post_traverse, []}],
                    Block: [tag: Block, post_traverse: {Block, :post_traverse, []}],
                    Root: [post_traverse: :post_traverse]
                  ] ++ @keyword_mapping ++ @operator_mapping ++ @collected_mapping

  Pegasus.parser_from_file(Path.join(__DIR__, "grammar/grammar.y"), @parser_options)

  zig_parser =
    empty()
    |> post_traverse(empty(), :init)
    |> parsec(:Root)

  defparsecp(:parser, zig_parser)

  def parse(string) do
    case parser(string) do
      {:ok, _, "", parser, _, _} -> parser
    end
  end

  # parser combinators

  defp init(code, args, context, _, _) do
    {code, args, struct(__MODULE__, context)}
  end

  defp container_doc_comment(
         rest,
         [{:container_doc_comment, [comment]} | rest_args],
         context,
         _,
         _
       ) do
    {rest, rest_args, %{context | doc_comment: trim_doc_comment(comment, "//!")}}
  end

  defp doc_comment(rest, [{:doc_comment, [comment]} | rest_args], context, _, _) do
    {rest, [{:doc_comment, trim_doc_comment(comment, "///")} | rest_args], context}
  end

  defp trim_doc_comment(comment, separator) do
    comment
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.trim_leading(&1, separator))
    |> Enum.join("\n")
  end

  defp string_literal_single(rest, [{:STRINGLITERALSINGLE, [literal]} | rest_args], context, _, _) do
    trimmed_literal = String.trim(literal, ~S("))
    {rest, [trimmed_literal | rest_args], context}
  end

  def post_traverse("", args, context, _, _) do
    props =
      args
      |> Enum.reverse()
      |> Enum.group_by(&group_for/1, &value_for/1)

    {"", [], struct(context, props)}
  end

  @block_tags ~w(usingnamespace toplevelcomptime)a

  defp group_for(%TestDecl{}), do: :tests
  defp group_for(%Function{}), do: :functions
  defp group_for(%Const{}), do: :decls
  defp group_for(%Var{}), do: :decls
  defp group_for({tag, _}) when tag in @block_tags, do: tag

  defp value_for({tag, block}) when tag in @block_tags, do: block
  defp value_for(other), do: other
end
