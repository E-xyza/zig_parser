defmodule Zig.Parser.Test.StatementTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

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
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {var x = 1;}")

      assert {:var, _, {:x, _, {:integer, 1}}} = var
    end

    test "can be comptime" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {comptime var x = 1;}")

      assert {:var, %{comptime: true}, {:x, _, _}} = var
    end
  end

  describe "const declarations" do
    test "can be empty" do
      assert %Parser{toplevelcomptime: [{:block, _, [const]}]} =
               Parser.parse("comptime {const x = 1;}")

      assert {:const, _, {:x, _, {:integer, 1}}} = const
    end

    test "can be comptime" do
      assert %Parser{toplevelcomptime: [{:block, _, [const]}]} =
               Parser.parse("comptime {comptime const x = 1;}")

      assert {:const, %{comptime: true}, {:x, _, _}} = const
    end
  end

  describe "prefixed block declarations" do
    test "can be comptime" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {comptime {}}")

      assert {:comptime, _, {:block, _, []}} = var
    end

    test "can be nosuspend" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {nosuspend {}}")

      assert {:nosuspend, _, {:block, _, []}} = var
    end

    test "can be suspend" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {suspend {}}")

      assert {:suspend, _, {:block, _, []}} = var
    end

    test "can be defer" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} = Parser.parse("comptime {defer {}}")

      assert {:defer, _, {:block, _, []}} = var
    end

    test "can be errdefer" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {errdefer {}}")

      assert {:errdefer, _, {:block, _, []}} = var
    end

    test "can be errdefer with a payload" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {errdefer |err| {}}")

      assert {:errdefer, _, {:payload, :err, {:block, _, []}}} = var
    end
  end

  describe "prefixed expressions" do
    test "can be comptime" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {comptime if (x) y;}")

      assert {:comptime, _, {:if, _, _}} = var
    end

    test "can be nosuspend" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {nosuspend if (x) y;}")

      assert {:nosuspend, _, {:if, _, _}} = var
    end

    test "can be suspend" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {suspend if (x) y;}")

      assert {:suspend, _, {:if, _, _}} = var
    end

    test "can be defer" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {defer if (x) y;}")

      assert {:defer, _, {:if, _, _}} = var
    end

    test "can be errdefer" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {errdefer if (x) y;}")

      assert {:errdefer, _, {:if, _, _}} = var
    end

    test "can be errdefer with payload" do
      assert %Parser{toplevelcomptime: [{:block, _, [var]}]} =
               Parser.parse("comptime {errdefer |err| if (x) y;}")

      assert {:errdefer, _, {:payload, :err, {:if, _, _}}} = var
    end
  end

  describe "statement can be if" do
    test "with basic" do
      assert %Parser{
               toplevelcomptime: [{:block, _, [{:if, _, [condition: :x, consequence: :y]}]}]
             } = Parser.parse("comptime {if (x) y;}")
    end

    test "with payload" do
      assert %Parser{
               toplevelcomptime: [
                 {:block, _, [{:if, _, [condition: :x, payload: :arg, consequence: :y]}]}
               ]
             } = Parser.parse("comptime {if (x) |arg| y;}")
    end

    test "with pointer payload" do
      assert %Parser{
               toplevelcomptime: [
                 {:block, _, [{:if, _, [condition: :x, ptr_payload: :arg, consequence: :y]}]}
               ]
             } = Parser.parse("comptime {if (x) |*arg| y;}")
    end

    test "with else" do
      assert %Parser{
               toplevelcomptime: [
                 {:block, _, [{:if, _, [condition: :x, consequence: :y, else: :z]}]}
               ]
             } = Parser.parse("comptime {if (x) y else z; }")
    end
  end

  describe "statement can be for" do
    test "basic" do
      assert %Parser{toplevelcomptime: [{:block, _, [forast]}]} =
               Parser.parse("comptime {for (x) |value| {}}")

      assert {:for, _, [enum: :x, payload: :value, do: {:block, _, _}]} = forast
    end

    test "with label" do
      assert %Parser{toplevelcomptime: [{:block, _, [forast]}]} =
               Parser.parse("comptime {loop: for (x) |value| {}}")

      assert {:for, %{label: :loop}, _} = forast
    end

    test "with inline" do
      assert %Parser{toplevelcomptime: [{:block, _, [forast]}]} =
               Parser.parse("comptime {inline for (x) |value| {}}")

      assert {:for, %{inline: true}, _} = forast
    end

    test "with label and inline" do
      assert %Parser{toplevelcomptime: [{:block, _, [forast]}]} =
               Parser.parse("comptime {loop: inline for (x) |value| {}}")

      assert {:for, %{inline: true, label: :loop}, _} = forast
    end

    test "with a single statement" do
      assert %Parser{toplevelcomptime: [{:block, _, [forast]}]} =
               Parser.parse("comptime {for (x) |value| this;}")

      assert {:for, _, [enum: :x, payload: :value, do: :this]} = forast
    end
  end

  describe "statement can be while" do
    test "basic" do
      assert %Parser{toplevelcomptime: [{:block, _, [whileast]}]} =
               Parser.parse("comptime {while (x) {}}")

      assert {:while, %{label: nil, inline: false}, condition: :x, do: {:block, _, []}} = whileast
    end

    test "with label" do
      assert %Parser{toplevelcomptime: [{:block, _, [whileast]}]} =
               Parser.parse("comptime {loop: while (x) {}}")

      assert {:while, %{label: :loop}, condition: :x, do: {:block, _, []}} = whileast
    end

    test "with inline" do
      assert %Parser{toplevelcomptime: [{:block, _, [whileast]}]} =
               Parser.parse("comptime {inline while (x) {}}")

      assert {:while, %{inline: true}, condition: :x, do: {:block, _, []}} = whileast
    end

    test "with label and inline" do
      assert %Parser{toplevelcomptime: [{:block, _, [whileast]}]} =
               Parser.parse("comptime {loop: inline while (x) {}}")

      assert {:while, %{inline: true, label: :loop}, condition: :x, do: {:block, _, []}} =
               whileast
    end

    test "with a single statement" do
      assert %Parser{toplevelcomptime: [{:block, _, [whileast]}]} =
               Parser.parse("comptime {while (x) this;}")

      assert {:while, _, condition: :x, do: :this} = whileast
    end
  end

  describe "statement can be switch" do
    test "basic" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {switch (expr) {}}")

      assert {:switch, _, [condition: :expr, switches: []]} = switchast
    end

    test "with one prong" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {switch (expr) {a => b}}")

      assert {:switch, _, [condition: :expr, switches: [a: :b]]} = switchast
    end

    test "with else" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {switch (expr) {
                a => b,
               else => c}}")

      assert {:switch, _, [condition: :expr, switches: [a: :b, else: :c]]} = switchast
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
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a *= b;}")

      assert {:"*=", _, [:a, :b]} = switchast
    end

    test "SLASHEQUAL => /=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a /= b;}")

      assert {:"/=", _, [:a, :b]} = switchast
    end

    test "PERCENTEQUAL => %=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a %= b;}")

      assert {:"%=", _, [:a, :b]} = switchast
    end

    test "PLUSEQUAL => +=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a += b;}")

      assert {:"+=", _, [:a, :b]} = switchast
    end

    test "MINUSEQUAL => -=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a -= b;}")

      assert {:"-=", _, [:a, :b]} = switchast
    end

    test "LARROW2EQUAL => <<=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a <<= b;}")

      assert {:"<<=", _, [:a, :b]} = switchast
    end

    test "RARROW2SEQUAL => >>=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a >>= b;}")

      assert {:">>=", _, [:a, :b]} = switchast
    end

    test "AMPERSANDEQUAL => &=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a &= b;}")

      assert {:"&=", _, [:a, :b]} = switchast
    end

    test "CARETEQUAL => ^=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a ^= b;}")

      assert {:"^=", _, [:a, :b]} = switchast
    end

    test "PIPEEQUAL => |=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a |= b;}")

      assert {:"|=", _, [:a, :b]} = switchast
    end

    test "ASTERISKPERCENTEQUAL => *%=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a *%= b;}")

      assert {:"*%=", _, [:a, :b]} = switchast
    end

    test "PLUSPERCENTEQUAL => +%=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a +%= b;}")

      assert {:"+%=", _, [:a, :b]} = switchast
    end

    test "MINUSPERCENTEQUAL => -%=" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a -%= b;}")

      assert {:"-%=", _, [:a, :b]} = switchast
    end

    test "EQUAL => =" do
      assert %Parser{toplevelcomptime: [{:block, _, [switchast]}]} =
               Parser.parse("comptime {a = b;}")

      assert {:=, _, [:a, :b]} = switchast
    end
  end
end
