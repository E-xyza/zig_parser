defmodule Zig.Parser.Test.StatementTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const
  alias Zig.Parser.If
  alias Zig.Parser.Var

  #
  # TESTS:
  # Statement
  #   <- KEYWORD_comptime? VarDecl
  #    / KEYWORD_comptime BlockExprStatement
  #    / KEYWORD_nosuspend BlockExprStatement
  #    / KEYWORD_suspend BlockExprStatement
  #    / KEYWORD_defer BlockExprStatement
  #    / KEYWORD_errdefer Payload? BlockExprStatement
  #    / IfStatement
  #    / LabeledStatement
  #    / SwitchExpr
  #    / AssignExpr SEMICOLON

  describe "var declarations" do
    test "can be runtime" do
      assert [%{code: [%Var{name: :x, value: {:integer, 1}}]}] =
               Parser.parse("comptime {var x = 1;}").code
    end

    test "can be comptime" do
      [%{code: [%Var{comptime: true}]}] = Parser.parse("comptime {comptime var x = 1;}").code
    end
  end

  describe "const declarations" do
    test "can be runtime" do
      assert [%{code: [%Const{name: :x, value: {:integer, 1}}]}] =
               Parser.parse("comptime {const x = 1;}").code
    end

    test "can be comptime" do
      [%{code: [%Const{comptime: true}]}] = Parser.parse("comptime {comptime const x = 1;}").code
    end
  end

  describe "comptime declarations" do
    test "can apply to a block" do
      [%{code: [%Block{comptime: true}]}] = Parser.parse("comptime {comptime {}}").code
    end

    test "can be nosuspend" do
      [%{code: [%Block{nosuspend: true}]}] = Parser.parse("comptime {nosuspend {}}").code
    end

    test "can be suspend" do
      [%{code: [%Block{suspend: true}]}] = Parser.parse("comptime {suspend {}}").code
    end

    test "can be defer" do
      [%{code: [{:defer, %Block{}}]}] = Parser.parse("comptime {defer {}}").code
    end

    test "can be errdefer" do
      [%{code: [{:errdefer, %Block{}}]}] = Parser.parse("comptime {errdefer {}}").code
    end

    test "can be errdefer with a payload" do
      [%{code: [{:errdefer, :err, %Block{}}]}] = Parser.parse("comptime {errdefer |err| {}}").code
    end
  end

  describe "prefixed expressions" do
    test "can be comptime" do
      assert [%{code: [%If{comptime: true}]}] =
               Parser.parse("comptime {comptime if (x) y;}").code
    end

    test "can be nosuspend" do
      assert [%{code: [{:nosuspend, %If{}}]}] =
               Parser.parse("comptime {nosuspend if (x) y;}").code
    end

    test "can be suspend" do
      assert [%{code: [{:suspend, %If{}}]}] = Parser.parse("comptime {suspend if (x) y;}").code
    end

    test "can be defer" do
      assert [%{code: [{:defer, %If{}}]}] = Parser.parse("comptime {defer if (x) y;}").code
    end

    test "can be errdefer" do
      assert [%{code: [{:errdefer, %If{}}]}] = Parser.parse("comptime {errdefer if (x) y;}").code
    end

    test "can be errdefer with payload" do
      assert [%{code: [{:errdefer, :err, %If{}}]}] =
               Parser.parse("comptime {errdefer |err| if (x) y;}").code
    end
  end

  describe "statement can be assign expression" do
    # AssignOp
    # <- ASTERISKEQUAL
    #  / SLASHEQUAL
    #  / PERCENTEQUAL
    #  / PLUSEQUAL
    #  / MINUSEQUAL
    #  / LARROW2EQUAL
    #  / RARROW2EQUAL
    #  / AMPERSANDEQUAL
    #  / CARETEQUAL
    #  / PIPEEQUAL
    #  / ASTERISKPERCENTEQUAL
    #  / PLUSPERCENTEQUAL
    #  / MINUSPERCENTEQUAL
    #  / EQUAL

    for assign_op <- ~w[*= /= %= += -= <<= >>= &= ^= |= *%= +%= -%= *|= +|= -|= <<|= =]a do
      test "operator #{assign_op}" do
        assert [%{code: [{unquote(assign_op), :a, :b}]}] =
                 Parser.parse("comptime {a #{unquote(assign_op)} b;}").code
      end
    end
  end
end
