defmodule Zig.Parser.Test.TopLevelVarTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  describe "top level declarations on top level var blocks" do
    # tests:
    # TopLevelDecl <- doc_comment? KEYWORD_pub? (TopLevelFn / TopLevelVar / Usingnamespace)
    test "get doc comment for vars" do
      assert %Parser{
               decls: [
                 %Var{
                   doc_comment: " this is a doc comment\n"
                 }
               ]
             } =
               Parser.parse("""
               /// this is a doc comment
               var foo: u32 = undefined;
               """)
    end

    test "can identify pub for var" do
      assert %Parser{
               decls: [
                 %Var{
                   pub: true
                 }
               ]
             } =
               Parser.parse("""
               pub var foo: u32 = undefined;
               """)
    end

    test "get doc comments for const" do
      assert %Parser{
               decls: [
                 %Const{
                   doc_comment: " this is a doc comment\n"
                 }
               ]
             } =
               Parser.parse("""
               /// this is a doc comment
               const foo = 100;
               """)
    end

    test "can identify pub for const" do
      assert %Parser{
               decls: [
                 %Const{
                   pub: true
                 }
               ]
             } =
               Parser.parse("""
               pub const foo = 100;
               """)
    end
  end

  describe "when given a top level basic var block" do
    # tests:
    # TopLevelVar <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? VarDecl
    # and all of the pieces that come with this part of the function proto, plus distinguishing between
    # var and const

    test "it can be found" do
      assert %Parser{
               decls: [
                 %Var{
                   export: false,
                   extern: false,
                   threadlocal: false,
                   name: :foo
                 }
               ]
             } = Parser.parse("var foo: u32 = undefined;")
    end

    test "export is flagged" do
      assert %Parser{decls: [%Var{export: true}]} =
               Parser.parse("export var foo: u32 = undefined;")
    end

    test "extern is flagged" do
      assert %Parser{decls: [%Var{extern: true}]} =
               Parser.parse("extern var foo: u32 = undefined;")
    end

    test "extern can be typed" do
      assert %Parser{decls: [%Var{extern: "C"}]} =
               Parser.parse(~S|extern "C" var foo: u32 = undefined;|)
    end

    test "threadlocal is flagged" do
      assert %Parser{decls: [%Var{threadlocal: true}]} =
               Parser.parse("threadlocal var foo: u32 = undefined;")
    end
  end

  describe "when given a basic top level const block" do
    test "it can be found" do
      assert %Parser{decls: [%Const{name: :foo}]} = Parser.parse("const foo = 100;")
    end
  end

  describe "when given contents of the var decl" do
    # tests:
    # VarDecl <- (KEYWORD_const / KEYWORD_var) IDENTIFIER (COLON TypeExpr)? ByteAlign? LinkSection? (EQUAL Expr)? SEMICOLON
    # and all of the pieces that come with this part of the var decl proto, plus distinguishing between
    # var and const

    test "adds byte alignment" do
      assert %Parser{decls: [%Var{align: {:integer, 8}}]} =
               Parser.parse("var foo: u32 align(8) = undefined;")
    end

    test "extern is flagged" do
      assert %Parser{decls: [%Var{linksection: {:enum_literal, :foo}}]} =
               Parser.parse("var foo: u32 linksection(.foo) = undefined;")
    end
  end
end
