defmodule Zig.Parser.Test.OperatorsTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const

  describe "binary operators in expressions" do
    # tests:
    # BoolOrExpr <- BoolAndExpr (KEYWORD_or BoolAndExpr)*
    # BoolAndExpr <- CompareExpr (KEYWORD_and CompareExpr)*
    # CompareExpr <- BitwiseExpr (CompareOp BitwiseExpr)?
    # BitwiseExpr <- BitShiftExpr (BitwiseOp BitShiftExpr)*
    # BitShiftExpr <- AdditionExpr (BitShiftOp AdditionExpr)*
    # AdditionExpr <- MultiplyExpr (AdditionOp MultiplyExpr)*
    # MultiplyExpr <- PrefixExpr (MultiplyOp PrefixExpr)*
    #
    # CompareOp  <- EQUALEQUAL
    #      / EXCLAMATIONMARKEQUAL
    #      / LARROW
    #      / RARROW
    #      / LARROWEQUAL
    #      / RARROWEQUAL
    #
    # BitwiseOp
    #     <- AMPERSAND
    #      / CARET
    #      / PIPE
    #      / KEYWORD_orelse
    #      / KEYWORD_catch Payload?
    #
    # BitShiftOp
    #     <- LARROW2
    #      / RARROW2
    #
    # AdditionOp
    #     <- PLUS
    #      / MINUS
    #      / PLUS2
    #      / PLUSPERCENT
    #      / MINUSPERCENT
    #
    # MultiplyOp
    #     <- PIPE2
    #      / ASTERISK
    #      / SLASH
    #      / PERCENT
    #      / ASTERISK2
    #      / ASTERISKPERCENT

    test "or operator" do
      assert %Parser{decls: [%Const{value: {:or, _, [:a, :b]}}]} =
               Parser.parse("const foo = a or b;")
    end

    test "and operator" do
      assert %Parser{decls: [%Const{value: {:and, _, [:a, :b]}}]} =
               Parser.parse("const foo = a and b;")
    end

    test "equals operator" do
      assert %Parser{decls: [%Const{value: {:==, _, [:a, :b]}}]} =
               Parser.parse("const foo = a == b;")
    end

    test "notequals operator" do
      assert %Parser{decls: [%Const{value: {:!=, _, [:a, :b]}}]} =
               Parser.parse("const foo = a != b;")
    end

    test "less than operator" do
      assert %Parser{decls: [%Const{value: {:<, _, [:a, :b]}}]} =
               Parser.parse("const foo = a < b;")
    end

    test "greater than operator" do
      assert %Parser{decls: [%Const{value: {:>, _, [:a, :b]}}]} =
               Parser.parse("const foo = a > b;")
    end

    test "less than or equals operator" do
      assert %Parser{decls: [%Const{value: {:<=, _, [:a, :b]}}]} =
               Parser.parse("const foo = a <= b;")
    end

    test "greater than or equal operator" do
      assert %Parser{decls: [%Const{value: {:>=, _, [:a, :b]}}]} =
               Parser.parse("const foo = a >= b;")
    end

    test "bitwise and operator" do
      assert %Parser{decls: [%Const{value: {:&, _, [:a, :b]}}]} =
               Parser.parse("const foo = a & b;")
    end

    test "bitwise xor operator" do
      assert %Parser{decls: [%Const{value: {:^, _, [:a, :b]}}]} =
               Parser.parse("const foo = a ^ b;")
    end

    test "bitwise or operator" do
      assert %Parser{decls: [%Const{value: {:|, _, [:a, :b]}}]} =
               Parser.parse("const foo = a | b;")
    end

    test "orelse operator" do
      assert %Parser{decls: [%Const{value: {:orelse, _, [:a, :b]}}]} =
               Parser.parse("const foo = a orelse b;")
    end

    test "leftshift operator" do
      assert %Parser{decls: [%Const{value: {:"<<", _, [:a, :b]}}]} =
               Parser.parse("const foo = a << b;")
    end

    test "rightshift operator" do
      assert %Parser{decls: [%Const{value: {:">>", _, [:a, :b]}}]} =
               Parser.parse("const foo = a >> b;")
    end

    test "plus operator" do
      assert %Parser{decls: [%Const{value: {:+, _, [:a, :b]}}]} =
               Parser.parse("const foo = a + b;")
    end

    test "minus operator" do
      assert %Parser{decls: [%Const{value: {:-, _, [:a, :b]}}]} =
               Parser.parse("const foo = a - b;")
    end

    test "comptime array concatentaion operator" do
      assert %Parser{decls: [%Const{value: {:++, _, [:a, :b]}}]} =
               Parser.parse("const foo = a ++ b;")
    end

    test "pluspercent operator" do
      assert %Parser{decls: [%Const{value: {:"+%", _, [:a, :b]}}]} =
               Parser.parse("const foo = a +% b;")
    end

    test "minuspercent operator" do
      assert %Parser{decls: [%Const{value: {:"-%", _, [:a, :b]}}]} =
               Parser.parse("const foo = a -% b;")
    end

    test "boolean or operator" do
      assert %Parser{decls: [%Const{value: {:||, _, [:a, :b]}}]} =
               Parser.parse("const foo = a || b;")
    end

    test "multiply operator" do
      assert %Parser{decls: [%Const{value: {:*, _, [:a, :b]}}]} =
               Parser.parse("const foo = a * b;")
    end

    test "divide operator" do
      assert %Parser{decls: [%Const{value: {:/, _, [:a, :b]}}]} =
               Parser.parse("const foo = a / b;")
    end

    test "modulo operator" do
      assert %Parser{decls: [%Const{value: {:%, _, [:a, :b]}}]} =
               Parser.parse("const foo = a % b;")
    end

    test "array repeat operator" do
      assert %Parser{decls: [%Const{value: {:**, _, [:a, :b]}}]} =
               Parser.parse("const foo = a ** b;")
    end

    test "wraparound multiply operator" do
      assert %Parser{decls: [%Const{value: {:"*%", _, [:a, :b]}}]} =
               Parser.parse("const foo = a *% b;")
    end
  end

  test "the catch operator"

  describe "unary prefix operators in expressions" do
    test "boolean negation operator" do
      assert %Parser{decls: [%Const{value: {:!, _, :a}}]} = Parser.parse("const foo = !a;")
    end

    test "arithmetic negation operator" do
      assert %Parser{decls: [%Const{value: {:-, _, :a}}]} = Parser.parse("const foo = -a;")
    end

    test "bitwise negation operator" do
      assert %Parser{decls: [%Const{value: {:"~", _, :a}}]} =
               Parser.parse("const foo = ~a;")
    end

    test "dereference operator" do
      assert %Parser{decls: [%Const{value: {:&, _, :a}}]} = Parser.parse("const foo = &a;")
    end

    test "try operator" do
      assert %Parser{decls: [%Const{value: {:try, _, :a}}]} =
               Parser.parse("const foo = try a;")
    end

    test "await operator" do
      assert %Parser{decls: [%Const{value: {:await, _, :a}}]} =
               Parser.parse("const foo = await a;")
    end
  end
end
