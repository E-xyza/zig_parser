defmodule Zig.Parser.Test.TopLevelVarTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  describe "top level declarations on top level var blocks" do
    test "get doc comment for vars" do
      assert [%Var{doc_comment: " this is a doc comment\n"}] =
               Parser.parse("""
               /// this is a doc comment
               var foo: u32 = undefined;
               """).code
    end

    test "can identify pub for var" do
      assert [%Var{pub: true}] =
               Parser.parse("""
               pub var foo: u32 = undefined;
               """).code
    end

    test "get doc comments for const" do
      assert [%Const{doc_comment: " this is a doc comment\n"}] =
               Parser.parse("""
               /// this is a doc comment
               const foo = 100;
               """).code
    end

    test "can identify pub for const" do
      assert [%Const{pub: true}] =
               Parser.parse("""
               pub const foo = 100;
               """).code
    end
  end

  describe "when given a top level basic var block" do
    # tests:
    # TopLevelVar <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? GlobalVarDecl
    # and all of the pieces that come with this part of the function proto, plus distinguishing between
    # var and const

    test "it can be found" do
      assert [
               %Var{
                 export: false,
                 extern: false,
                 threadlocal: false
               }
             ] = Parser.parse("var foo: u32 = undefined;").code
    end

    test "export is flagged" do
      assert [%Var{export: true}] =
               Parser.parse("export var foo: u32 = undefined;").code
    end

    test "extern is flagged" do
      assert [%Var{extern: true}] =
               Parser.parse("extern var foo: u32 = undefined;").code
    end

    test "extern can be typed" do
      assert [%Var{extern: "C"}] =
               Parser.parse(~S|extern "C" var foo: u32 = undefined;|).code
    end

    test "threadlocal is flagged" do
      assert [%Var{threadlocal: true}] =
               Parser.parse("threadlocal var foo: u32 = undefined;").code
    end

    test "addrspace is marked" do
      assert [%Var{addrspace: :gpu}] =
               Parser.parse("var foo: u32 addrspace(.gpu) = undefined;").code
    end
  end

  describe "when given a basic top level const block" do
    test "it can be found" do
      assert [%Const{name: :foo}] = Parser.parse("const foo = 100;").code
    end
  end

  describe "when given contents of the var decl" do
    # tests:
    # GlobalVarDecl <- (KEYWORD_const / KEYWORD_var) IDENTIFIER (COLON TypeExpr)? ByteAlign? LinkSection? (EQUAL Expr)? SEMICOLON
    # and all of the pieces that come with this part of the var decl proto, plus distinguishing between
    # var and const

    test "adds byte alignment" do
      assert [%Var{alignment: {:integer, 8}}] =
               Parser.parse("var foo: u32 align(8) = undefined;").code
    end

    test "extern is flagged" do
      assert [%Var{linksection: :foo}] =
               Parser.parse("var foo: u32 linksection(.foo) = undefined;").code
    end
  end

  describe "corner cases" do
    test "var doesn't need a value, per the parser" do
      assert [%Var{}] = Parser.parse("extern var foo: u8;").code
    end
  end
end
