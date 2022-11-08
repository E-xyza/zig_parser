defmodule Zig.Parser.Test.TypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # tests:
  #
  # note that PrimaryTypeExpr is generally tested in primary_type_expr_.exs
  #
  # TypeExpr <- PrefixTypeOp* ErrorUnionExpr
  # ErrorUnionExpr <- SuffixExpr (EXCLAMATIONMARK TypeExpr)?
  # PrefixTypeOp
  #   <- QUESTIONMARK
  #    / KEYWORD_anyframe MINUSRARROW
  #    / SliceTypeStart (ByteAlign / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
  #    / PtrTypeStart (KEYWORD_align LPAREN Expr (COLON INTEGER COLON INTEGER)? RPAREN / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
  #    / ArrayTypeStart
  #
  # SuffixExpr
  #    <- KEYWORD_async PrimaryTypeExpr SuffixOp* FnCallArguments
  #     / PrimaryTypeExpr (SuffixOp / FnCallArguments)*
  #
  # SuffixOp
  #   <- LBRACKET Expr (DOT2 (Expr? (COLON Expr)?)?)? RBRACKET
  #    / DOT IDENTIFIER
  #    / DOTASTERISK
  #    / DOTQUESTIONMARK
  #
  # SliceTypeStart <- LBRACKET (COLON Expr)? RBRACKET
  #
  # PtrTypeStart
  #     <- ASTERISK
  #      / ASTERISK2
  #      / LBRACKET ASTERISK (LETTERC / COLON Expr)? RBRACKET
  #
  # ArrayTypeStart <- LBRACKET Expr (COLON Expr)? RBRACKET

  defmacro const_with(expr) do
    quote do
      [{:const, _, {:foo, _, unquote(expr)}}]
    end
  end

  describe "the questionmark prefix" do
    test "tags as optional_type" do
      assert const_with({:optional_type, :u8}) = Parser.parse("const foo = ?u8;").code
    end

    test "tags a ref as optional_type" do
      assert const_with({:optional_type, {:ref, [:std, :foo]}}) =
               Parser.parse("const foo = ?std.foo;").code
    end
  end

  describe "the anyframe prefix" do
    test "tags as anyframe" do
      assert const_with({:anyframe, :u8}) = Parser.parse("const foo = anyframe -> u8;").code
    end

    test "tags as anyframe with ref" do
      assert const_with({:anyframe, {:ref, [:std, :foo]}}) =
               Parser.parse("const foo = anyframe -> std.foo;").code
    end
  end

  describe "the slicetypestart prefix" do
    test "with no sentinel" do
      assert const_with(
               {:slice,
                %{
                  align: nil,
                  const: false,
                  volatile: false,
                  allowzero: false
                }, type: :u8}
             ) = Parser.parse("const foo = []u8;").code
    end

    test "with a sentinel" do
      assert const_with({:slice, _, type: :u8, sentinel: {:integer, 0}}) =
               Parser.parse("const foo = [:0]u8;").code
    end

    test "with align" do
      assert const_with({:slice, %{align: {:integer, 8}}, _}) =
               Parser.parse("const foo = [] align(8) u8;").code
    end

    test "with const" do
      assert const_with({:slice, %{const: true}, _}) =
               Parser.parse("const foo = [] const u8;").code
    end

    test "with volatile" do
      assert const_with({:slice, %{volatile: true}, _}) =
               Parser.parse("const foo = [] volatile u8;").code
    end

    test "with allowzero" do
      assert const_with({:slice, %{allowzero: true}, _}) =
               Parser.parse("const foo = [] allowzero u8;").code
    end
  end

  describe "the ptrtypestart prefix" do
    test "basic single pointer" do
      assert const_with(
               {:ptr,
                %{
                  align: nil,
                  const: false,
                  volatile: false,
                  allowzero: false
                }, type: :u8}
             ) = Parser.parse("const foo = *u8;").code
    end

    test "with alignment" do
      assert const_with({:ptr, %{align: {:integer, 8}}, _}) =
               Parser.parse("const foo = *align(8)u8;").code
    end

    test "with extended alignment" do
      assert const_with({:ptr, %{align: {{:integer, 8}, 2, 1}}, _}) =
               Parser.parse("const foo = *align(8:2:1)u8;").code
    end

    test "with const" do
      assert const_with({:ptr, %{const: true}, _}) = Parser.parse("const foo = *const u8;").code
    end

    test "with volatile" do
      assert const_with({:ptr, %{volatile: true}, _}) =
               Parser.parse("const foo = *volatile u8;").code
    end

    test "with allowzero" do
      assert const_with({:ptr, %{allowzero: true}, _}) =
               Parser.parse("const foo = *allowzero u8;").code
    end

    test "double pointer" do
      # this is necessary because double pointer is parsed differently due to it also being an
      # operator.
      assert const_with({:ptr, _, {:ptr, _, type: :u8}}) = Parser.parse("const foo = **u8;").code
    end

    test "multi pointers" do
      assert const_with({:multiptr, _, type: :u8}) = Parser.parse("const foo = [*]u8;").code
    end

    test "c pointers" do
      assert const_with({:cptr, _, type: :u8}) = Parser.parse("const foo = [*c]u8;").code
    end

    test "multi pointers with sentinel" do
      assert const_with({:multiptr, _, type: :u8, sentinel: {:integer, 0}}) =
               Parser.parse("const foo = [*:0]u8;").code
    end

    # NB: C pointer with sentinel is kind of not parsing correctly.
  end

  describe "the array prefix" do
    test "works with specified length" do
      assert const_with({:array, _, length: {:integer, 3}, type: :u8}) =
               Parser.parse("const foo = [3]u8;").code
    end

    test "works with inferred length" do
      assert const_with({:array, _, length: :_, type: :u8}) =
               Parser.parse("const foo = [_]u8;").code
    end

    test "works with specified length and sentinel" do
      assert const_with({:array, _, length: {:integer, 3}, type: :u8, sentinel: {:integer, 0}}) =
               Parser.parse("const foo = [3:0]u8;").code
    end

    test "works with inferred length and sentinel" do
      assert const_with({:array, _, length: :_, type: :u8, sentinel: {:integer, 0}}) =
               Parser.parse("const foo = [_:0]u8;").code
    end
  end

  describe "async function call" do
    test "works" do
      assert const_with({:async, {:bar, _, []}}) = Parser.parse("const foo = async bar();").code
    end
  end

  describe "dereferenced content" do
    test "that is basic with a pointer pointer" do
      assert const_with({:ptrref, :bar}) = Parser.parse("const foo = bar.*;").code
    end

    test "that is basic with a required" do
      assert const_with({:required, :bar}) = Parser.parse("const foo = bar.?;").code
    end

    test "that is a field" do
      assert const_with({:ref, [:bar, :baz]}) = Parser.parse("const foo = bar.baz;").code
    end

    test "that is an array" do
      assert const_with({:ref, [:bar, {:index, {:integer, 10}}]}) =
               Parser.parse("const foo = bar[10];").code
    end

    test "that makes a slice" do
      assert const_with({:ref, [:bar, {:slice, {:integer, 1}, {:integer, 5}}]}) =
               Parser.parse("const foo = bar[1..5];").code
    end

    test "that makes a slice with a sentinel" do
      assert const_with(
               {:ref, [:bar, {:slice, {:integer, 1}, {:integer, 5}, sentinel: {:integer, 0}}]}
             ) = Parser.parse("const foo = bar[1..5:0];").code
    end

    test "that makes a slice with inferred end" do
      assert const_with({:ref, [:bar, {:slice, {:integer, 1}, :end}]}) =
               Parser.parse("const foo = bar[1..];").code
    end

    test "that is a pointer" do
      assert const_with({:ptrref, [:bar, :baz, {:index, {:integer, 10}}, :quux]}) =
               Parser.parse("const foo = bar.baz[10].quux.*;").code
    end

    test "that is a required" do
      assert const_with({:required, [:bar, :baz, {:index, {:integer, 10}}, :quux]}) =
               Parser.parse("const foo = bar.baz[10].quux.?;").code
    end
  end

  describe "function calls" do
    test "no parameter" do
      assert const_with({:bar, _, []}) = Parser.parse("const foo = bar();").code
    end

    test "one parameter" do
      assert const_with({:bar, _, [integer: 1]}) = Parser.parse("const foo = bar(1);").code
    end

    test "two parameters" do
      assert const_with({:bar, _, [integer: 1, integer: 2]}) =
               Parser.parse("const foo = bar(1, 2);").code
    end

    test "a ref as a base" do
      assert const_with({{:ref, [:bar, :baz]}, _, []}) =
               Parser.parse("const foo = bar.baz();").code
    end

    test "continuation of ref" do
      assert const_with({:ref, [{{:ref, [:bar, :baz]}, _, []}, :quux]}) =
               Parser.parse("const foo = bar.baz().quux;").code
    end
  end

  describe "error unions" do
    test "one union" do
      assert const_with({:errorunion, [:bar, :baz]}) = Parser.parse("const foo = bar!baz;").code
    end

    test "multi union" do
      assert const_with({:errorunion, [:bar, :baz, :quux]}) =
               Parser.parse("const foo = bar!baz!quux;").code
    end
  end
end
