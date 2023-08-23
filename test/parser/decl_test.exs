defmodule Zig.Parser.Test.ContainerDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Function
  alias Zig.Parser.Var

  # TESTS:
  # Decl
  #   <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE? / (KEYWORD_inline / KEYWORD_noinline))? FnProto (SEMICOLON / Block)
  #      / (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? VarDecl
  #      / KEYWORD_usingnamespace Expr SEMICOLON

  describe "FnProto decorator with no block" do
    test "export works" do
      assert [%Function{export: true}] = Parser.parse("export fn myfun() void;").code
    end

    test "extern works" do
      assert [%Function{extern: true}] = Parser.parse("extern fn myfun() void;").code
    end

    test "extern with a decorator works" do
      assert [%Function{extern: "c"}] = Parser.parse("extern \"c\" fn myfun() void;").code
    end

    test "inline works" do
      assert [%Function{inline: true}] = Parser.parse("inline fn myfun() void;").code
    end

    test "noinline works" do
      assert [%Function{inline: false}] = Parser.parse("noinline fn myfun() void;").code
    end

    test "with a block works" do
      assert [%Function{block: %{code: []}}] = Parser.parse("fn myfun() void {}").code
    end

    test "gets the location correct" do
      assert [_, %Function{location: {2, 1}}] =
               Parser.parse(~S"""
               const foo = 1;
               fn myfun() void {}
               """).code
    end
  end

  describe "variable decl" do
    test "export works" do
      assert [%Var{export: true}] = Parser.parse("export var abc: int32 = undefined;").code
    end

    test "extern works" do
      assert [%Var{extern: true}] = Parser.parse("extern var abc: int32 = undefined;").code
    end

    test "extern with a decorator works" do
      assert [%Var{extern: "c"}] = Parser.parse("extern \"c\" var abc: int32 = undefined;").code
    end

    test "threadlocal works" do
      assert [%Var{threadlocal: true}] =
               Parser.parse("threadlocal var abc: int32 = undefined;").code
    end

    test "location is identified" do
      assert [_, %Var{location: {2, 1}}] =
               Parser.parse(~S"""
               const foo = 1;
               var abc: int32 = undefined;
               """).code
    end
  end

  describe "usingnamespace works" do
    alias Zig.Parser.Struct

    test "with an identifier" do
      assert [{:usingnamespace, :std}] = Parser.parse("usingnamespace std;").code
    end

    test "with a struct" do
      assert [{:usingnamespace, %Struct{}}] =
               Parser.parse("usingnamespace struct{};").code
    end

    test "with an import" do
      assert [{:usingnamespace, {:call, :import, [string: "std"]}}] =
               Parser.parse("usingnamespace @import(\"std\");").code
    end
  end
end
