defmodule Zig.Parser.Test.ContainerDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  alias Zig.Parser
  alias Zig.Parser.Const

  # TESTS:
  # ContainerDecl <- (KEYWORD_extern / KEYWORD_packed)? ContainerDeclAuto
  #
  # ContainerDeclAuto <- ContainerDeclType LBRACE container_doc_comment? ContainerMembers RBRACE
  #
  # ContainerDeclType
  #   <- KEYWORD_struct
  #    / KEYWORD_opaque
  #    / KEYWORD_enum (LPAREN Expr RPAREN)?
  #    / KEYWORD_union (LPAREN (KEYWORD_enum (LPAREN Expr RPAREN)? / Expr) RPAREN)?
  #
  # ContainerMembers <- ContainerDeclarations (ContainerField COMMA)* (ContainerField / ContainerDeclarations)

  describe "struct container decl" do
    test "can be parsed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} = Parser.parse("const foo = struct{};")
      assert {:struct, %{extern: false, packed: false}, []} = expr
    end

    test "can be extern" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = extern struct{};")

      assert {:struct, %{extern: true}, []} = expr
    end

    test "can be packed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed struct{};")

      assert {:struct, %{packed: true}, []} = expr
    end

    test "can have a one line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = struct{
                 //! this is a comment
               };
               """)

      assert {:struct, %{comment: " this is a comment\n"}, []} = expr
    end

    test "can have a multi line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = struct{
                 //! this is a comment
                 //! this is also a comment
               };
               """)

      assert {:struct, %{comment: " this is a comment\n this is also a comment\n"}, []} = expr
    end
  end

  describe "opaque container decl" do
    test "can be parsed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} = Parser.parse("const foo = opaque{};")
      assert {:opaque, %{extern: false, packed: false}, []} = expr
    end

    test "can be extern" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = extern opaque{};")

      assert {:opaque, %{extern: true}, []} = expr
    end

    test "can be packed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed opaque{};")

      assert {:opaque, %{packed: true}, []} = expr
    end

    test "can have a one line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = opaque{
                 //! this is a comment
               };
               """)

      assert {:opaque, %{comment: " this is a comment\n"}, []} = expr
    end

    test "can have a multi line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = opaque{
                 //! this is a comment
                 //! this is also a comment
               };
               """)

      assert {:opaque, %{comment: " this is a comment\n this is also a comment\n"}, []} = expr
    end
  end

  describe "enum container decl" do
    test "can be parsed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} = Parser.parse("const foo = enum{};")
      assert {:enum, %{extern: false, packed: false, type: nil}, []} = expr
    end

    test "can be extern" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = extern enum{};")

      assert {:enum, %{extern: true}, []} = expr
    end

    test "can be packed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed enum{};")

      assert {:enum, %{packed: true}, []} = expr
    end

    test "can be typed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed enum(u8) {};")

      assert {:enum, %{packed: true, type: :u8}, []} = expr
    end

    test "can have a one line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = enum{
                 //! this is a comment
               };
               """)

      assert {:enum, %{comment: " this is a comment\n"}, []} = expr
    end

    test "can have a multi line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = enum{
                 //! this is a comment
                 //! this is also a comment
               };
               """)

      assert {:enum, %{comment: " this is a comment\n this is also a comment\n"}, []} = expr
    end
  end

  describe "union container decl" do
    test "can be parsed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} = Parser.parse("const foo = union{};")
      assert {:union, %{extern: false, packed: false, tagtype: nil}, []} = expr
    end

    test "can be extern" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = extern union{};")

      assert {:union, %{extern: true}, []} = expr
    end

    test "can be packed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed union{};")

      assert {:union, %{packed: true}, []} = expr
    end

    test "can be typed" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed union(my_enum) {};")

      assert {:union, %{packed: true, tagtype: :my_enum}, []} = expr
    end

    test "can have an inferred enum type" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed union(enum) {};")

      assert {:union, %{packed: true, tagtype: nil, tagged: true}, []} = expr
    end

    test "can have a backed, inferred enum type" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("const foo = packed union(enum(u8)) {};")

      assert {:union, %{packed: true, tagtype: {:enum, :u8}, tagged: true}, []} = expr
    end

    test "can have a one line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = union{
                 //! this is a comment
               };
               """)

      assert {:union, %{comment: " this is a comment\n"}, []} = expr
    end

    test "can have a multi line doc comment" do
      assert %Parser{decls: [{:const, _, {_, _, expr}}]} =
               Parser.parse("""
               const foo = union{
                 //! this is a comment
                 //! this is also a comment
               };
               """)

      assert {:union, %{comment: " this is a comment\n this is also a comment\n"}, []} = expr
    end
  end

  test "container contents"
end
