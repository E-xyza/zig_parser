defmodule Zig.Parser.Test.ContainerDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Function

  # TESTS:
  # Decl
  #   <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE? / (KEYWORD_inline / KEYWORD_noinline))? FnProto (SEMICOLON / Block)
  #      / (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? VarDecl
  #      / KEYWORD_usingnamespace Expr SEMICOLON

  describe "FnProto decorator with no block" do
    test "export works" do
      assert [%{export: true}] = Parser.parse("export fn myfun() void;").code
    end

    test "extern works" do
      assert [%{extern: true}] = Parser.parse("extern fn myfun() void;").code
    end

    test "extern with a decorator works" do
      assert [%{extern: "c"}] = Parser.parse("extern \"c\" fn myfun() void;").code
    end

    test "inline works" do
      assert [%{inline: true}] = Parser.parse("inline fn myfun() void;").code
    end

    test "noinline works" do
      assert [%{inline: false}] = Parser.parse("noinline fn myfun() void;").code
    end

    test "with a block works" do
      assert [%{block: %{code: []}}] = Parser.parse("fn myfun() void {}").code
    end
  end

  describe "variable decl" do
    test "export works" do
      assert [%{export: true}] = Parser.parse("export var abc: int32 = undefined;").code
    end

    test "extern works" do
      assert [%{extern: true}] = Parser.parse("extern var abc: int32 = undefined;").code
    end

    test "extern with a decorator works" do
      assert [%{extern: "c"}] = Parser.parse("extern \"c\" var abc: int32 = undefined;").code
    end

    test "threadlocal works" do
      assert [%{threadlocal: true}] = Parser.parse("threadlocal var abc: int32 = undefined;").code
    end
  end

  describe "usingnamespace works" do
    alias Zig.Parser.Struct

    test "with an identifier" do
      assert [%{namespace: :std}] = Parser.parse("usingnamespace std;").code
    end

    test "with a struct" do
      assert [%{namespace: %Struct{}}] = Parser.parse("usingnamespace struct{};").code
    end

    test "with an import" do
      assert [%{namespace: %Function{builtin: true}}] =
               Parser.parse("usingnamespace @import(\"std\");").code
    end
  end
end
