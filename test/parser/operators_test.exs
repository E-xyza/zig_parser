defmodule Zig.Parser.Test.OperatorsTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block

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
    #      / LARROW2PIPE
    #
    # AdditionOp
    #     <- PLUS
    #      / MINUS
    #      / PLUS2
    #      / PLUSPERCENT
    #      / MINUSPERCENT
    #      / PLUSPIPE
    #      / MINUSPIPE
    #
    # MultiplyOp
    #     <- PIPE2
    #      / ASTERISK
    #      / SLASH
    #      / PERCENT
    #      / ASTERISK2
    #      / ASTERISKPERCENT
    #      / ASTERISKPIPE

    @binary_operators ~w[
      or and
      == != < > <= >=
      & ^ | orelse
      << >> <<|
      + - ++ +% -% +| -|
      || * / % ** *% *|]a

    for op <- @binary_operators do
      test "#{op}" do
        assert [%{value: {unquote(op), :a, :b}}] =
                 Parser.parse("const foo = a #{unquote(op)} b;").code
      end
    end
  end

  describe "the catch operator" do
    test "value with no payload" do
      assert [%{value: {:catch, :x, {:integer, 10}}}] =
               Parser.parse("const foo = x catch 10;").code
    end

    test "value that is a block" do
      assert [%{value: {:catch, :x, %Block{}}}] =
               Parser.parse("const foo = x catch {};").code
    end

    test "with a payload" do
      assert [%{value: {:catch, :x, :err, %Block{}}}] =
               Parser.parse("const foo = x catch |err| {};").code
    end
  end

  @unary_operators ~w[! - -% ~ & try await]a

  describe "unary prefix operators in expressions" do
    for op <- @unary_operators do
      test "#{op}" do
        assert [%{value: {unquote(op), :a}}] = Parser.parse("const foo = #{unquote(op)} a;").code
      end
    end
  end
end
