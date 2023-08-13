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
      assert [%Function{linksection: :foo}] =
               Parser.parse("fn foo() linksection(.foo) void {}").code
    end

    test "can obtain call convention" do
      assert [%Function{callconv: :C}] =
               Parser.parse("fn foo() callconv(.C) void {}").code
    end

    test "can be impliciterror" do
      assert [%Function{impliciterror: true}] =
               Parser.parse("fn foo() !void {}").code
    end
  end

  # describe "function parameters" do
  #  test "can have one argument" do
  #    assert [{:fn, _, opts}] = Parser.parse("fn foo(bar: u8) void {}").code
  #    assert [{:bar, _, :u8}] = opts[:params]
  #  end
  #
  #  test "can have two arguments" do
  #    assert [{:fn, _, opts}] = Parser.parse("fn foo(bar: u8, baz: u32) void {}").code
  #    assert [{:bar, _, :u8}, {:baz, _, :u32}] = opts[:params]
  #  end
  #
  #  test "can have a doc comment" do
  #    assert [{:fn, _, opts}] =
  #             Parser.parse("""
  #             fn foo(
  #               /// this is a comment
  #               bar: u8
  #             ) void {}
  #             """).code
  #
  #    assert [{:bar, %{doc_comment: " this is a comment\n"}, _}] = opts[:params]
  #  end
  #
  #  test "can be noalias" do
  #    assert [{:fn, _, opts}] = Parser.parse("fn foo(noalias bar: u8) void {}").code
  #    assert [{:bar, %{noalias: true}, _}] = opts[:params]
  #  end
  #
  #  test "can be comptime" do
  #    assert [{:fn, _, opts}] = Parser.parse("fn foo(comptime bar: u8) void {}").code
  #    assert [{:bar, %{comptime: true}, _}] = opts[:params]
  #  end
  #
  #  test "can have no name" do
  #    assert [{:fn, _, opts}] = Parser.parse("fn foo(u8) void {}").code
  #    assert [{:_, _, :u8}] = opts[:params]
  #  end
  #
  #  test "can be a vararg" do
  #    assert [{:fn, _, opts}] = Parser.parse("fn foo(...) void {}").code
  #    assert [:...] = opts[:params]
  #  end
  # end
end
