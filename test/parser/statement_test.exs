defmodule Zig.Parser.Test.StatementTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  # this test (ab)uses the comptime block to track statement information
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
    test "can be empty" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {var x = 1;}")

      assert %Var{name: :x, value: {:integer, 1}} = var
    end

    test "can be comptime" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {comptime var x = 1;}")

      assert %Var{name: :x, comptime: true} = var
    end
  end

  describe "const declarations" do
    test "can be empty" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {const x = 1;}")

      assert %Const{name: :x, value: {:integer, 1}} = var
    end

    test "can be comptime" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {comptime const x = 1;}")

      assert %Const{name: :x, comptime: true} = var
    end
  end

  describe "prefixed block declarations" do
    test "can be comptime" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {comptime {}}")

      assert {:comptime, %Block{code: []}} = var
    end

    test "can be nosuspend" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {nosuspend {}}")

      assert {:nosuspend, %Block{code: []}} = var
    end

    test "can be suspend" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {suspend {}}")

      assert {:suspend, %Block{code: []}} = var
    end

    test "can be defer" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {defer {}}")

      assert {:defer, %Block{code: []}} = var
    end

    test "can be errdefer" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {errdefer {}}")

      assert {:errdefer, %Block{code: []}} = var
    end

    test "can be errdefer with a payload" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {errdefer |err| {}}")

      assert {:errdefer, {:payload, :err, %Block{code: []}}} = var
    end
  end

  describe "prefixed expressions" do
    test "can be comptime" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {comptime if (x) y;}")

      assert {:comptime, {:if, %{expr: "x"}, %{expr: "y"}}} = var
    end

    test "can be nosuspend" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {nosuspend if (x) y;}")

      assert {:nosuspend, {:if, %{expr: "x"}, %{expr: "y"}}} = var
    end

    test "can be suspend" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {suspend if (x) y;}")

      assert {:suspend, {:if, %{expr: "x"}, %{expr: "y"}}} = var
    end

    test "can be defer" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {defer if (x) y;}")

      assert {:defer, {:if, %{expr: "x"}, %{expr: "y"}}} = var
    end

    test "can be errdefer" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {errdefer if (x) y;}")

      assert {:errdefer, {:if, %{expr: "x"}, %{expr: "y"}}} = var
    end

    test "can be errdefer with paylod" do
      assert %Parser{toplevelcomptime: [%Block{code: [var]}]} =
               Parser.parse("comptime {errdefer |err| if (x) y;}")

      assert {:errdefer, {:payload, :err, {:if, %{expr: "x"}, %{expr: "y"}}}} = var
    end
  end

  describe "statement can be if" do
    test "with basic" do
      assert %Parser{toplevelcomptime: [%Block{code: [{:if, %{expr: "x"}, %{expr: "y"}}]}]} =
               Parser.parse("comptime {if (x) y;}")
    end

    test "with payload" do
      assert %Parser{
               toplevelcomptime: [
                 %Block{code: [{:if, %{expr: "x"}, {:payload, :arg, %{expr: "y"}}}]}
               ]
             } = Parser.parse("comptime {if (x) |arg| y;}")
    end

    test "with pointer payload" do
      assert %Parser{
               toplevelcomptime: [
                 %Block{code: [{:if, %{expr: "x"}, {:ptr_payload, :arg, %{expr: "y"}}}]}
               ]
             } = Parser.parse("comptime {if (x) |*arg| y;}")
    end

    test "with else" do
      assert %Parser{
               toplevelcomptime: [%Block{code: [{:if, %{expr: "x"}, %{expr: "y"}, %{expr: "z"}}]}]
             } = Parser.parse("comptime {if (x) y else z; }")
    end
  end

  describe "statement can be for" do
    test "basic" do
      assert %Parser{toplevelcomptime: [%Block{code: [forast]}]} =
               Parser.parse("comptime {for (x) |value| {}}")

      assert {:for, %{expr: "x"}, :value, %{code: []}} = forast
    end

    test "with label" do
      assert %Parser{toplevelcomptime: [%Block{code: [forast]}]} =
               Parser.parse("comptime {loop: for (x) |value| {}}")

      assert {{:for, :loop}, %{expr: "x"}, :value, %{code: []}} = forast
    end

    test "with inline" do
      assert %Parser{toplevelcomptime: [%Block{code: [forast]}]} =
               Parser.parse("comptime {inline for (x) |value| {}}")

      assert {:inline_for, %{expr: "x"}, :value, %{code: []}} = forast
    end

    test "with label and inline" do
      assert %Parser{toplevelcomptime: [%Block{code: [forast]}]} =
               Parser.parse("comptime {loop: inline for (x) |value| {}}")

      assert {{:inline_for, :loop}, %{expr: "x"}, :value, %{code: []}} = forast
    end

    test "with a single statement" do
      assert %Parser{toplevelcomptime: [%Block{code: [forast]}]} =
               Parser.parse("comptime {inline for (x) |value| this;}")

      assert {:inline_for, %{expr: "x"}, :value, %{expr: "this"}} = forast
    end
  end

  describe "statement can be while" do
    test "basic" do
      assert %Parser{toplevelcomptime: [%Block{code: [whileast]}]} =
               Parser.parse("comptime {while (x) {}}")

      assert {:while, %{expr: "x"}, %{code: []}} = whileast
    end

    test "with label" do
      assert %Parser{toplevelcomptime: [%Block{code: [whileast]}]} =
               Parser.parse("comptime {loop: while (x) {}}")

      assert {{:while, :loop}, %{expr: "x"}, %{code: []}} = whileast
    end

    test "with inline" do
      assert %Parser{toplevelcomptime: [%Block{code: [whileast]}]} =
               Parser.parse("comptime {inline while (x) {}}")

      assert {:inline_while, %{expr: "x"}, %{code: []}} = whileast
    end

    test "with label and inline" do
      assert %Parser{toplevelcomptime: [%Block{code: [whileast]}]} =
               Parser.parse("comptime {loop: inline while (x) {}}")

      assert {{:inline_while, :loop}, %{expr: "x"}, %{code: []}} = whileast
    end

    test "with a single statement" do
      assert %Parser{toplevelcomptime: [%Block{code: [whileast]}]} =
               Parser.parse("comptime {while (x) this;}")

      assert {:while, %{expr: "x"}, %{expr: "this"}} = whileast
    end
  end

  describe "statement can be switch" do
    test "basic" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {switch (expr) {}}")

      assert {:switch, %{expr: "expr"}, []} = switchast
    end

    test "with one prong" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {switch (expr) {a => b}}")

      assert {:switch, %{expr: "expr"}, [{%{expr: "a"}, %{expr: "b"}}]} = switchast
    end

    test "with else" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {switch (expr) {
                a => b,
               else => c}}")

      assert {:switch, %{expr: "expr"}, [{%{expr: "a"}, %{expr: "b"}}, {:else, %{expr: "c"}}]} =
               switchast
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

    test "ASTERISKEQUAL => *=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a *= b;}")

      assert {:"*=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "SLASHEQUAL => /=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a /= b;}")

      assert {:"/=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "PERCENTEQUAL => %=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a %= b;}")

      assert {:"%=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "PLUSEQUAL => +=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a += b;}")

      assert {:"+=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "MINUSEQUAL => -=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a -= b;}")

      assert {:"-=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "LARROW2EQUAL => <<=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a <<= b;}")

      assert {:"<<=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "RARROW2SEQUAL => >>=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a >>= b;}")

      assert {:">>=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "AMPERSANDEQUAL => &=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a &= b;}")

      assert {:"&=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "CARETEQUAL => ^=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a ^= b;}")

      assert {:"^=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "PIPEEQUAL => |=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a |= b;}")

      assert {:"|=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "ASTERISKPERCENTEQUAL => *%=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a *%= b;}")

      assert {:"*%=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "PLUSPERCENTEQUAL => +%=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a +%= b;}")

      assert {:"+%=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "MINUSPERCENTEQUAL => -%=" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a -%= b;}")

      assert {:"-%=", %{expr: "a"}, %{expr: "b"}} = switchast
    end

    test "EQUAL => =" do
      assert %Parser{toplevelcomptime: [%Block{code: [switchast]}]} =
               Parser.parse("comptime {a = b;}")

      assert {:=, %{expr: "a"}, %{expr: "b"}} = switchast
    end
  end
end
