defmodule Zig.Parser.Test.PrimaryTypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  alias Zig.Parser

  # TESTS:
  #
  # PrimaryTypeExpr
  # <- BUILTINIDENTIFIER FnCallArguments
  #  / CHAR_LITERAL
  #  / ContainerDecl
  #  / DOT IDENTIFIER
  #  / DOT InitList
  #  / ErrorSetDecl
  #  / FLOAT
  #  / FnProto
  #  / GroupedExpr
  #  / LabeledTypeExpr
  #  / IDENTIFIER
  #  / IfTypeExpr
  #  / INTEGER
  #  / KEYWORD_comptime TypeExpr
  #  / KEYWORD_error DOT IDENTIFIER
  #  / KEYWORD_anyframe
  #  / KEYWORD_unreachable
  #  / STRINGLITERAL
  #  / SwitchExpr

  defmacrop const_with(expr) do
    quote do
      [{:const, _, {_, _, unquote(expr)}}]
    end
  end

  describe "builtin function" do
    test "with no arguments" do
      assert const_with(expr) = Parser.parse("const foo = @builtin_fn();").code

      assert {:builtin, :builtin_fn, []} = expr
    end

    test "with one arguments" do
      assert const_with(expr) = Parser.parse("const foo = @builtin_fn(foo);").code

      assert {:builtin, :builtin_fn, [:foo]} = expr
    end

    test "with two arguments" do
      assert const_with(expr) = Parser.parse("const foo = @builtin_fn(foo, bar);").code

      assert {:builtin, :builtin_fn, [:foo, :bar]} = expr
    end
  end

  describe "char literal" do
    test "basic ascii" do
      assert const_with(?a) = Parser.parse("const foo = 'a';").code
    end

    @tag :skip
    test "utf-8 literal" do
      assert const_with(?🚀) = Parser.parse("const foo = '🚀';").code
    end

    test "escaped char" do
      assert const_with(?\t) = Parser.parse("const foo = '\\t';").code
    end

    test "escaped hex" do
      assert const_with(?🚀) = Parser.parse("const foo = '\\u{1F680}';").code
    end
  end

  describe "container decl" do
    # see container_decl_test.exs
  end

  describe "enum literal" do
    test "is parsed" do
      assert const_with({:enum_literal, :foo}) = Parser.parse("const foo = .foo;").code
    end
  end

  describe "initlist" do
    test "for anonymous struct with one item" do
      assert const_with({:anonymous_struct, %{foo: :bar}}) =
               Parser.parse("const foo = .{.foo = bar};").code
    end

    test "for anonymous struct with more items" do
      assert const_with({:anonymous_struct, %{foo: :bar, bar: :baz}}) =
               Parser.parse("const foo = .{.foo = bar, .bar = baz};").code
    end

    test "for tuple with one item" do
      assert const_with({:tuple, [:foo]}) = Parser.parse("const foo = .{foo};").code
    end

    test "for tuple with more than one item" do
      assert const_with({:tuple, [:foo, :bar]}) = Parser.parse("const foo = .{foo, bar};").code
    end

    test "for empty tuple" do
      assert const_with({:empty}) = Parser.parse("const foo = .{};").code
    end
  end

  describe "errorsetdecl" do
    test "with one error" do
      assert const_with({:errorset, [:abc]}) = Parser.parse("const foo = error {abc};").code
    end

    test "with more than one error" do
      assert const_with({:errorset, [:abc, :bcd]}) = Parser.parse("const foo = error {abc, bcd};").code
    end
  end
end
