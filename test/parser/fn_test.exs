defmodule Zig.Parser.Test.FunctionTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Function

  describe "when given a top-level function" do
    # tests:
    # TopLevelFn  <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE? / (KEYWORD_inline / KEYWORD_noinline))? FnProto (SEMICOLON / Block)
    # and all of the pieces that come with this part of the function proto.

    test "it can be found" do
      assert %Parser{
               functions: [
                 %Function{
                   export: false,
                   extern: false,
                   inline: :maybe,
                   name: :foo,
                   block: {:block, _, []}
                 }
               ]
             } = Parser.parse("fn foo() void {}")
    end

    test "it can be export" do
      assert %Parser{
               functions: [
                 %Function{export: true}
               ]
             } = Parser.parse("export fn foo() void {}")
    end

    test "it can be extern" do
      assert %Parser{
               functions: [
                 %Function{extern: true, block: nil}
               ]
             } = Parser.parse("extern fn foo() void;")
    end

    test "it can be extern with a type" do
      assert %Parser{
               functions: [
                 %Function{extern: "C", block: nil}
               ]
             } = Parser.parse(~S|extern "C" fn foo() void;|)
    end

    test "it can be forced inline" do
      assert %Parser{
               functions: [
                 %Function{inline: true}
               ]
             } = Parser.parse("inline fn foo() void {}")
    end

    test "it can be forced noinline" do
      assert %Parser{
               functions: [
                 %Function{inline: false}
               ]
             } = Parser.parse("noinline fn foo() void {}")
    end
  end

  describe "when given a top-level named function the prototype" do
    # tests:
    # FnProto <- KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr

    test "has correct defaults" do
      assert %Parser{
               functions: [
                 %Function{
                   name: :foo,
                   params: [],
                   align: nil,
                   linksection: nil,
                   callconv: nil,
                   type: :void
                 }
               ]
             } = Parser.parse("fn foo() void {}")
    end

    test "can obtain byte alignment" do
      assert %Parser{functions: [%Function{align: {:integer, 32}}]} =
               Parser.parse("fn foo() align(32) void {}")
    end

    test "can obtain link section" do
      assert %Parser{functions: [%Function{linksection: {:enum_literal, :foo}}]} =
               Parser.parse("fn foo() linksection(.foo) void {}")
    end

    test "can obtain call convention" do
      assert %Parser{functions: [%Function{callconv: {:enum_literal, :C}}]} =
               Parser.parse("fn foo() callconv(.C) void {}")
    end
  end
end
