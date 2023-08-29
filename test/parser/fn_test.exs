defmodule Zig.Parser.Test.FunctionTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Function

  # note that general properties (e.g. extern, inline) are found in decl_test.exs

  describe "function properties" do
    # tests:
    # FnProto <- KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr

    test "has correct defaults" do
      assert [
               %Function{
                 alignment: nil,
                 linksection: nil,
                 callconv: nil,
                 impliciterror: false
               }
             ] = Parser.parse("fn foo() void {}").code
    end

    test "can obtain byte alignment" do
      assert [%Function{alignment: {:integer, 32}}] =
               Parser.parse("fn foo() align(32) void {}").code
    end

    test "can obtain link section" do
      assert [%Function{linksection: {:enum_literal, :foo}}] =
               Parser.parse("fn foo() linksection(.foo) void {}").code
    end

    test "can obtain call convention" do
      assert [%Function{callconv: {:enum_literal, :C}}] =
               Parser.parse("fn foo() callconv(.C) void {}").code
    end

    test "can be impliciterror" do
      assert [%Function{impliciterror: true}] =
               Parser.parse("fn foo() !void {}").code
    end

    test "reports location" do
      assert [_, %Function{location: {2, 1}}] =
               Parser.parse(~S"""
               const a = 1;
               fn foo() !void {}
               """).code
    end
  end

  describe "function parameters" do
    test "can have one argument" do
      assert [%Function{params: [%{name: :bar, type: :u8}]}] =
               Parser.parse("fn foo(bar: u8) void {}").code
    end

    test "can have two arguments" do
      assert [%Function{params: [%{name: :bar, type: :u8}, %{name: :baz, type: :u32}]}] =
               Parser.parse("fn foo(bar: u8, baz: u32) void {}").code
    end

    test "can have a doc comment" do
      assert [%Function{params: [%{doc_comment: doc_comment}]}] =
               Parser.parse("""
               fn foo(
                 /// this is a comment
                 bar: u8
               ) void {}
               """).code

      assert doc_comment =~ "this is a comment"
    end

    test "can be noalias" do
      assert [%{params: [%{noalias: true}]}] =
               Parser.parse("fn foo(noalias bar: u8) void {}").code
    end

    test "can be comptime" do
      assert [%{params: [%{comptime: true}]}] =
               Parser.parse("fn foo(comptime bar: u8) void {}").code
    end

    test "can have no name" do
      assert [%{params: [%{name: nil, type: :u8}]}] = Parser.parse("fn foo(u8) void {}").code
    end

    test "can be a vararg" do
      assert [%{params: [%{type: :...}]}] = Parser.parse("fn foo(...) void {}").code
    end
  end

  describe "function type odds and ends" do
    test "function type with decorator" do
      assert [%{value: %Function{}}] = Parser.parse("const x = fn () callconv(WINAPI) void;").code
    end

    test "optional comma is ok" do
      [%{value: %Function{}}] = Parser.parse("const x = fn (u8,) void;").code
    end
  end
end
