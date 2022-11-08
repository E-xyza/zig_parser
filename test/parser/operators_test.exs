defmodule Zig.Parser.Test.OperatorsTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

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

    defmacrop const_with(expr) do
      quote do
        [{:const, _, {_, _, unquote(expr)}}]
      end
    end

    test "or operator" do
      assert const_with({:or, _, [:a, :b]}) = Parser.parse("const foo = a or b;").code
    end

    test "and operator" do
      assert const_with({:and, _, [:a, :b]}) = Parser.parse("const foo = a and b;").code
    end

    test "equals operator" do
      assert const_with({:==, _, [:a, :b]}) = Parser.parse("const foo = a == b;").code
    end

    test "notequals operator" do
      assert const_with({:!=, _, [:a, :b]}) = Parser.parse("const foo = a != b;").code
    end

    test "less than operator" do
      assert const_with({:<, _, [:a, :b]}) = Parser.parse("const foo = a < b;").code
    end

    test "greater than operator" do
      assert const_with({:>, _, [:a, :b]}) = Parser.parse("const foo = a > b;").code
    end

    test "less than or equals operator" do
      assert const_with({:<=, _, [:a, :b]}) = Parser.parse("const foo = a <= b;").code
    end

    test "greater than or equal operator" do
      assert const_with({:>=, _, [:a, :b]}) = Parser.parse("const foo = a >= b;").code
    end

    test "bitwise and operator" do
      assert const_with({:&, _, [:a, :b]}) = Parser.parse("const foo = a & b;").code
    end

    test "bitwise xor operator" do
      assert const_with({:^, _, [:a, :b]}) = Parser.parse("const foo = a ^ b;").code
    end

    test "bitwise or operator" do
      assert const_with({:|, _, [:a, :b]}) = Parser.parse("const foo = a | b;").code
    end

    test "orelse operator" do
      assert const_with({:orelse, _, [:a, :b]}) = Parser.parse("const foo = a orelse b;").code
    end

    test "leftshift operator" do
      assert const_with({:"<<", _, [:a, :b]}) = Parser.parse("const foo = a << b;").code
    end

    test "rightshift operator" do
      assert const_with({:">>", _, [:a, :b]}) = Parser.parse("const foo = a >> b;").code
    end

    test "plus operator" do
      assert const_with({:+, _, [:a, :b]}) = Parser.parse("const foo = a + b;").code
    end

    test "minus operator" do
      assert const_with({:-, _, [:a, :b]}) = Parser.parse("const foo = a - b;").code
    end

    test "comptime array concatentaion operator" do
      assert const_with({:++, _, [:a, :b]}) = Parser.parse("const foo = a ++ b;").code
    end

    test "pluspercent operator" do
      assert const_with({:"+%", _, [:a, :b]}) = Parser.parse("const foo = a +% b;").code
    end

    test "minuspercent operator" do
      assert const_with({:"-%", _, [:a, :b]}) = Parser.parse("const foo = a -% b;").code
    end

    test "boolean or operator" do
      assert const_with({:||, _, [:a, :b]}) = Parser.parse("const foo = a || b;").code
    end

    test "multiply operator" do
      assert const_with({:*, _, [:a, :b]}) = Parser.parse("const foo = a * b;").code
    end

    test "divide operator" do
      assert const_with({:/, _, [:a, :b]}) = Parser.parse("const foo = a / b;").code
    end

    test "modulo operator" do
      assert const_with({:%, _, [:a, :b]}) = Parser.parse("const foo = a % b;").code
    end

    test "array repeat operator" do
      assert const_with({:**, _, [:a, :b]}) = Parser.parse("const foo = a ** b;").code
    end

    test "wraparound multiply operator" do
      assert const_with({:"*%", _, [:a, :b]}) = Parser.parse("const foo = a *% b;").code
    end
  end

  describe "the catch operator" do
    test "value with no payload" do
      assert const_with({:catch, _, [:x, {:integer, 10}]}) =
               Parser.parse("const foo = x catch 10;").code
    end

    test "value that is a block" do
      assert const_with({:catch, _, [:x, {:block, _, []}]}) =
               Parser.parse("const foo = x catch {};").code
    end

    test "with a payload" do
      assert const_with({:catch, _, [:x, {:block, _, []}, payload: :err]}) =
               Parser.parse("const foo = x catch |err| {};").code
    end
  end

  describe "unary prefix operators in expressions" do
    test "boolean negation operator" do
      assert const_with({:!, _, :a}) = Parser.parse("const foo = !a;").code
    end

    test "arithmetic negation operator" do
      assert const_with({:-, _, :a}) = Parser.parse("const foo = -a;").code
    end

    test "bitwise negation operator" do
      assert const_with({:"~", _, :a}) = Parser.parse("const foo = ~a;").code
    end

    test "dereference operator" do
      assert const_with({:&, _, :a}) = Parser.parse("const foo = &a;").code
    end

    test "try operator" do
      assert const_with({:try, _, :a}) = Parser.parse("const foo = try a;").code
    end

    test "await operator" do
      assert const_with({:await, _, :a}) = Parser.parse("const foo = await a;").code
    end
  end
end
