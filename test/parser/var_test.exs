defmodule Zig.Parser.Test.TopLevelVarTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  describe "top level declarations on top level var blocks" do
    # tests:
    # TopLevelDecl <- doc_comment? KEYWORD_pub? (TopLevelFn / TopLevelVar / Usingnamespace)
    test "get doc comment for vars" do
      assert [{:var, %{doc_comment: " this is a doc comment\n"}, {_, _, _}}] =
               Parser.parse("""
               /// this is a doc comment
               var foo: u32 = undefined;
               """).code
    end

    test "can identify pub for var" do
      assert [{:var, %{pub: true}, {_, _, _}}] =
               Parser.parse("""
               pub var foo: u32 = undefined;
               """).code
    end

    test "get doc comments for const" do
      assert [{:const, %{doc_comment: " this is a doc comment\n"}, _}] =
               Parser.parse("""
               /// this is a doc comment
               const foo = 100;
               """).code
    end

    test "can identify pub for const" do
      assert [{:const, %{pub: true}, _}] =
               Parser.parse("""
               pub const foo = 100;
               """).code
    end
  end

  describe "when given a top level basic var block" do
    # tests:
    # TopLevelVar <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? VarDecl
    # and all of the pieces that come with this part of the function proto, plus distinguishing between
    # var and const

    test "it can be found" do
      assert [
               {:var,
                %{
                  export: false,
                  extern: false,
                  threadlocal: false
                }, {_, _, _}}
             ] = Parser.parse("var foo: u32 = undefined;").code
    end

    test "export is flagged" do
      assert [{:var, %{export: true}, {_, _, _}}] =
               Parser.parse("export var foo: u32 = undefined;").code
    end

    test "extern is flagged" do
      assert [{:var, %{extern: true}, {_, _, _}}] =
               Parser.parse("extern var foo: u32 = undefined;").code
    end

    test "extern can be typed" do
      assert [{:var, %{extern: "C"}, {_, _, _}}] =
               Parser.parse(~S|extern "C" var foo: u32 = undefined;|).code
    end

    test "threadlocal is flagged" do
      assert [{:var, %{threadlocal: true}, {_, _, _}}] =
               Parser.parse("threadlocal var foo: u32 = undefined;").code
    end
  end

  describe "when given a basic top level const block" do
    test "it can be found" do
      assert [{:const, _, {:foo, _, _}}] = Parser.parse("const foo = 100;").code
    end
  end

  describe "when given contents of the var decl" do
    # tests:
    # VarDecl <- (KEYWORD_const / KEYWORD_var) IDENTIFIER (COLON TypeExpr)? ByteAlign? LinkSection? (EQUAL Expr)? SEMICOLON
    # and all of the pieces that come with this part of the var decl proto, plus distinguishing between
    # var and const

    test "adds byte alignment" do
      assert [{:var, %{align: {:integer, 8}}, {_, _, _}}] =
               Parser.parse("var foo: u32 align(8) = undefined;").code
    end

    test "extern is flagged" do
      assert [{:var, %{linksection: {:enum_literal, :foo}}, {_, _, _}}] =
               Parser.parse("var foo: u32 linksection(.foo) = undefined;").code
    end
  end
end
