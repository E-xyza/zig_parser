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
      assert [%{value: {:optional, :u8}}] = Parser.parse("const foo = ?u8;").code
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
      assert [%{value: %Array{count: {:integer, 3}, type: :u8}}] =
               Parser.parse("const foo = [3]u8;").code
    end

    test "works with auto length" do
      assert [%{value: %Array{count: :_, type: :u8}}] =
               Parser.parse("const foo = [_]u8;").code
    end

    test "works with sentinel" do
      assert [%{value: %Array{count: {:integer, 3}, sentinel: {:integer, 0}, type: :u8}}] =
               Parser.parse("const foo = [3:0]u8;").code
    end
  end

  # SuffixExpr

  describe "primary type expression, one deep" do
    # PrimaryTypeExpr (SuffixOp / FnCallArguments)*

    # SuffixOp
    #   <- LBRACKET Expr (DOT2 (Expr? (COLON Expr)?)?)? RBRACKET
    #    / DOT IDENTIFIER
    #    / DOTASTERISK
    #    / DOTQUESTIONMARK

    test "works for just an identifier" do
      assert [%{value: :bar}] = Parser.parse("const foo = bar;").code
    end

    test "works for an identifier + left bracket" do
      assert [%{value: {:ref, [:bar, {:index, :baz}]}}] =
               Parser.parse("const foo = bar[baz];").code
    end

    test "works for an identifier + open ended range" do
      assert [%{value: {:ref, [:bar, {:range, {:integer, 0}}]}}] =
               Parser.parse("const foo = bar[0..];").code
    end

    test "works for an identifier + range" do
      assert [%{value: {:ref, [:bar, {:range, {:integer, 0}, :baz}]}}] =
               Parser.parse("const foo = bar[0..baz];").code
    end

    test "works for an identifier + range + sentinel" do
      assert [%{value: {:ref, [:bar, {:range, {:integer, 0}, :baz, {:integer, 0}}]}}] =
               Parser.parse("const foo = bar[0..baz:0];").code
    end

    test "works for a pointer deref" do
      assert [%{value: {:ref, [:bar, :*]}}] = Parser.parse("const foo = bar.*;").code
    end

    test "works for a optional deref" do
      assert [%{value: {:ref, [:bar, :"?"]}}] = Parser.parse("const foo = bar.?;").code
    end

    test "works for a function call with no arguments" do
      assert [%{value: {:call, :bar, []}}] = Parser.parse("const foo = bar();").code
    end

    test "works for a function call with one argument" do
      assert [%{value: {:call, :bar, [:baz]}}] = Parser.parse("const foo = bar(baz);").code
    end
  end

  describe "primary type expression, multiple deep" do
    test "works for a double deep identifier" do
      assert [%{value: {:ref, [:bar, :baz]}}] = Parser.parse("const foo = bar.baz;").code
    end

    test "works for a triple deep identifier" do
      assert [%{value: {:ref, [:bar, :baz, :quux]}}] =
               Parser.parse("const foo = bar.baz.quux;").code
    end

    test "works for something really complex" do
      assert [
               %{
                 value: {
                   :call,
                   {:ref, [{:call, {:ref, [:bar, {:index, :baz}, :quux]}, []}, :mlem]},
                   [:blep]
                 }
               }
             ] = Parser.parse("const foo = bar[baz].quux().mlem(blep);").code
    end
  end

  describe "async function call" do
    test "works in the simple case" do
      assert [%{value: {:async, {:call, :bar, []}}}] =
               Parser.parse("const foo = async bar();").code
    end

    test "works in the more complex case" do
      assert [
               %{
                 value:
                   {:async, {:call, {:ref, [:bar, :baz, {:index, {:integer, 3}}, :quux]}, []}}
               }
             ] =
               Parser.parse("const foo = async bar.baz[3].quux();").code
    end
  end

  describe "as error unions" do
    test "basic error union" do
      assert [%{value: {:errorunion, :bar, :baz}}] = Parser.parse("const foo = bar!baz;").code
    end

    test "complex error union" do
      assert [
               %{
                 value:
                   {:errorunion, {:call, {:ref, [:bar, {:index, {:integer, 2}}]}, [:baz]},
                    {:call, :quux, [:mlem]}}
               }
             ] = Parser.parse("const foo = bar[2](baz)!quux(mlem);").code
    end
  end
end
