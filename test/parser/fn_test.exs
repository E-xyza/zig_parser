defmodule Zig.Parser.Test.FunctionTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  describe "when given a top-level function" do
    # tests:
    # TopLevelFn  <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE? / (KEYWORD_inline / KEYWORD_noinline))? FnProto (SEMICOLON / Block)
    # and all of the pieces that come with this part of the function proto.

    test "it can be found" do
      assert [
               {:fn,
                %{
                  export: false,
                  extern: false,
                  inline: :maybe
                }, name: :foo, params: [], type: :void, block: {:block, _, []}}
             ] = Parser.parse("fn foo() void {}").code
    end

    test "it can be export" do
      assert [{:fn, %{export: true}, _}] = Parser.parse("export fn foo() void {}").code
    end

    test "it can be extern" do
      assert [{:fn, %{extern: true}, _}] = Parser.parse("extern fn foo() void;").code
    end

    test "it can be extern with a type" do
      assert [{:fn, %{extern: "C"}, _}] = Parser.parse(~S|extern "C" fn foo() void;|).code
    end

    test "it can be forced inline" do
      assert [{:fn, %{inline: true}, _}] = Parser.parse("inline fn foo() void {}").code
    end

    test "it can be forced noinline" do
      assert [{:fn, %{inline: false}, _}] = Parser.parse("noinline fn foo() void {}").code
    end
  end

  describe "when given a top-level named function the prototype" do
    # tests:
    # FnProto <- KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr

    test "has correct defaults" do
      assert [
               {:fn,
                %{
                  align: nil,
                  linksection: nil,
                  callconv: nil
                }, name: :foo, params: [], type: :void, block: {:block, _, []}}
             ] = Parser.parse("fn foo() void {}").code
    end

    test "can obtain byte alignment" do
      assert [{:fn, %{align: {:integer, 32}}, _}] =
               Parser.parse("fn foo() align(32) void {}").code
    end

    test "can obtain link section" do
      assert [{:fn, %{linksection: {:enum_literal, :foo}}, _}] =
               Parser.parse("fn foo() linksection(.foo) void {}").code
    end

    test "can obtain call convention" do
      assert [{:fn, %{callconv: {:enum_literal, :C}}, _}] =
               Parser.parse("fn foo() callconv(.C) void {}").code
    end
  end
end
