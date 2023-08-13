defmodule Zig.Parser.Test.TypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Array
  alias Zig.Parser.Pointer

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

  describe "the questionmark prefix" do
    test "tags as optional_type" do
      assert [%{value: {:optional_type, :u8}}] = Parser.parse("const foo = ?u8;").code
    end
  end

  describe "the anyframe prefix" do
    test "tags as anyframe" do
      assert [%{value: {:anyframe, :u8}}] = Parser.parse("const foo = anyframe -> u8;").code
    end
  end

  describe "the slice prefix" do
    test "as plain" do
      assert [
               %{
                 value: %Pointer{
                   alignment: nil,
                   const: false,
                   volatile: false,
                   allowzero: false,
                   sentinel: nil,
                   count: :slice,
                   type: :u8
                 }
               }
             ] = Parser.parse("const foo = []u8;").code
    end

    test "with alignment" do
      assert [%{value: %Pointer{count: :slice, alignment: {:integer, 64}}}] =
               Parser.parse("const foo = [] align(64) u8;").code
    end

    test "with const" do
      assert [%{value: %Pointer{count: :slice, const: true}}] =
               Parser.parse("const foo = [] const u8;").code
    end

    test "with volatile" do
      assert [%{value: %Pointer{count: :slice, volatile: true}}] =
               Parser.parse("const foo = [] volatile u8;").code
    end

    test "with allowzero" do
      assert [%{value: %Pointer{count: :slice, allowzero: true}}] =
               Parser.parse("const foo = [] allowzero u8;").code
    end

    test "with a sentinel" do
      assert [%{value: %Pointer{count: :slice, sentinel: {:integer, 0}}}] =
               Parser.parse("const foo = [:0]u8;").code
    end
  end

  describe "the single star pointer prefix" do
    test "as plain" do
      assert [
               %{
                 value: %Pointer{
                   alignment: nil,
                   const: false,
                   volatile: false,
                   allowzero: false,
                   sentinel: nil,
                   count: :one,
                   type: :u8
                 }
               }
             ] = Parser.parse("const foo = *u8;").code
    end

    test "with basic alignment" do
      assert [%{value: %Pointer{count: :one, alignment: {:integer, 64}}}] =
               Parser.parse("const foo = *align(64) u8;").code
    end

    test "with detailed alignment" do
      assert [%{value: %Pointer{count: :one, alignment: {{:integer, 64}, 1, 1}}}] =
               Parser.parse("const foo = *align(64:1:1) u8;").code
    end

    test "with const" do
      assert [%{value: %Pointer{count: :one, const: true}}] =
               Parser.parse("const foo = *const u8;").code
    end

    test "with volatile" do
      assert [%{value: %Pointer{count: :one, volatile: true}}] =
               Parser.parse("const foo = *volatile u8;").code
    end

    test "with allowzero" do
      assert [%{value: %Pointer{count: :one, allowzero: true}}] =
               Parser.parse("const foo = *allowzero u8;").code
    end
  end

  describe "the double star pointer prefix" do
    test "as plain" do
      [
        %{
          value: %Pointer{
            count: :one,
            type: %Pointer{
              count: :one,
              type: :u8
            }
          }
        }
      ] = Parser.parse("const foo = **u8;").code
    end

    test "with const" do
      assert [%{value: %Pointer{type: %Pointer{count: :one, const: true}}}] =
               Parser.parse("const foo = **const u8;").code
    end

    test "with volatile" do
      assert [%{value: %Pointer{type: %Pointer{count: :one, volatile: true}}}] =
               Parser.parse("const foo = **volatile u8;").code
    end

    test "with allowzero" do
      assert [%{value: %Pointer{type: %Pointer{count: :one, allowzero: true}}}] =
               Parser.parse("const foo = **allowzero u8;").code
    end
  end

  describe "the manypointer prefix" do
    test "as plain" do
      assert [
               %{
                 value: %Pointer{
                   alignment: nil,
                   const: false,
                   volatile: false,
                   allowzero: false,
                   sentinel: nil,
                   count: :many,
                   type: :u8
                 }
               }
             ] = Parser.parse("const foo = [*]u8;").code
    end

    test "with basic alignment" do
      assert [%{value: %Pointer{count: :many, alignment: {:integer, 64}}}] =
               Parser.parse("const foo = [*]align(64) u8;").code
    end

    test "with detailed alignment" do
      assert [%{value: %Pointer{count: :many, alignment: {{:integer, 64}, 1, 1}}}] =
               Parser.parse("const foo = [*]align(64:1:1) u8;").code
    end

    test "with const" do
      assert [%{value: %Pointer{count: :many, const: true}}] =
               Parser.parse("const foo = [*]const u8;").code
    end

    test "with volatile" do
      assert [%{value: %Pointer{count: :many, volatile: true}}] =
               Parser.parse("const foo = [*]volatile u8;").code
    end

    test "with allowzero" do
      assert [%{value: %Pointer{count: :many, allowzero: true}}] =
               Parser.parse("const foo = [*]allowzero u8;").code
    end

    test "with sentinel" do
      assert [%{value: %Pointer{count: :many, sentinel: {:integer, 0}}}] =
               Parser.parse("const foo = [*:0]allowzero u8;").code
    end
  end

  describe "the c-pointer prefix" do
    test "as plain" do
      assert [
               %{
                 value: %Pointer{
                   alignment: nil,
                   const: false,
                   volatile: false,
                   allowzero: false,
                   sentinel: nil,
                   count: :c,
                   type: :u8
                 }
               }
             ] = Parser.parse("const foo = [*c]u8;").code
    end

    test "with basic alignment" do
      assert [%{value: %Pointer{count: :c, alignment: {:integer, 64}}}] =
               Parser.parse("const foo = [*c]align(64) u8;").code
    end

    test "with const" do
      assert [%{value: %Pointer{count: :c, const: true}}] =
               Parser.parse("const foo = [*c]const u8;").code
    end

    test "with volatile" do
      assert [%{value: %Pointer{count: :c, volatile: true}}] =
               Parser.parse("const foo = [*c]volatile u8;").code
    end

    test "with allowzero" do
      assert [%{value: %Pointer{count: :c, allowzero: true}}] =
               Parser.parse("const foo = [*c]allowzero u8;").code
    end
  end

  describe "the array prefix" do
    test "works with specified length" do
      assert [%{value: %Array{array: {:integer, 3}, type: :u8}}] =
               Parser.parse("const foo = [3]u8;").code
    end

    #
    #    test "works with inferred length" do
    #      assert const_with({:array, _, length: :_, type: :u8}) =
    #               Parser.parse("const foo = [_]u8;").code
    #    end
    #
    #    test "works with specified length and sentinel" do
    #      assert const_with({:array, _, length: {:integer, 3}, type: :u8, sentinel: {:integer, 0}}) =
    #               Parser.parse("const foo = [3:0]u8;").code
    #    end
    #
    #    test "works with inferred length and sentinel" do
    #      assert const_with({:array, _, length: :_, type: :u8, sentinel: {:integer, 0}}) =
    #               Parser.parse("const foo = [_:0]u8;").code
    #    end
  end

  #
  #  describe "async function call" do
  #    test "works" do
  #      assert const_with({:bar, %{async: true}, []}) =
  #               Parser.parse("const foo = async bar();").code
  #    end
  #  end
  #
  #  describe "dereferenced content" do
  #    test "that is basic with a pointer pointer" do
  #      assert const_with({:ptrref, :bar}) = Parser.parse("const foo = bar.*;").code
  #    end
  #
  #    test "that is basic with a required" do
  #      assert const_with({:required, :bar}) = Parser.parse("const foo = bar.?;").code
  #    end
  #
  #    test "that is a field" do
  #      assert const_with({:ref, [:bar, :baz]}) = Parser.parse("const foo = bar.baz;").code
  #    end
  #
  #    test "that is an array" do
  #      assert const_with({:ref, [:bar, {:index, {:integer, 10}}]}) =
  #               Parser.parse("const foo = bar[10];").code
  #    end
  #
  #    test "that makes a slice" do
  #      assert const_with({:ref, [:bar, {:slice, {:integer, 1}, {:integer, 5}}]}) =
  #               Parser.parse("const foo = bar[1..5];").code
  #    end
  #
  #    test "that makes a slice with a sentinel" do
  #      assert const_with(
  #               {:ref, [:bar, {:slice, {:integer, 1}, {:integer, 5}, sentinel: {:integer, 0}}]}
  #             ) = Parser.parse("const foo = bar[1..5:0];").code
  #    end
  #
  #    test "that makes a slice with inferred end" do
  #      assert const_with({:ref, [:bar, {:slice, {:integer, 1}, :end}]}) =
  #               Parser.parse("const foo = bar[1..];").code
  #    end
  #
  #    test "that is a pointer" do
  #      assert const_with({:ptrref, [:bar, :baz, {:index, {:integer, 10}}, :quux]}) =
  #               Parser.parse("const foo = bar.baz[10].quux.*;").code
  #    end
  #
  #    test "that is a required" do
  #      assert const_with({:required, [:bar, :baz, {:index, {:integer, 10}}, :quux]}) =
  #               Parser.parse("const foo = bar.baz[10].quux.?;").code
  #    end
  #  end
  #
  #  describe "function calls" do
  #    test "no parameter" do
  #      assert const_with({:bar, _, []}) = Parser.parse("const foo = bar();").code
  #    end
  #
  #    test "one parameter" do
  #      assert const_with({:bar, _, [integer: 1]}) = Parser.parse("const foo = bar(1);").code
  #    end
  #
  #    test "two parameters" do
  #      assert const_with({:bar, _, [integer: 1, integer: 2]}) =
  #               Parser.parse("const foo = bar(1, 2);").code
  #    end
  #
  #    test "a ref as a base" do
  #      assert const_with({{:ref, [:bar, :baz]}, _, []}) =
  #               Parser.parse("const foo = bar.baz();").code
  #    end
  #
  #    test "continuation of ref" do
  #      assert const_with({:ref, [{{:ref, [:bar, :baz]}, _, []}, :quux]}) =
  #               Parser.parse("const foo = bar.baz().quux;").code
  #    end
  #  end
  #
  #  describe "error unions" do
  #    test "one union" do
  #      assert const_with({:errorunion, [:bar, :baz]}) = Parser.parse("const foo = bar!baz;").code
  #    end
  #
  #    test "multi union" do
  #      assert const_with({:errorunion, [:bar, :baz, :quux]}) =
  #               Parser.parse("const foo = bar!baz!quux;").code
  #    end
  #  end
end
