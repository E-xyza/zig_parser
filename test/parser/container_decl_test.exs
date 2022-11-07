defmodule Zig.Parser.Test.ContainerDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  alias Zig.Parser

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

  defmacrop const_with(expr) do
    quote do
      [{:const, _, {_, _, unquote(expr)}}]
    end
  end

  describe "struct container decl" do
    test "can be parsed" do
      const_with(expr) = Parser.parse("const foo = struct{};").code
      assert {:struct, %{extern: false, packed: false}, _} = expr
    end

    test "can be extern" do
      const_with(expr) = Parser.parse("const foo = extern struct{};").code
      assert {:struct, %{extern: true}, _} = expr
    end

    test "can be packed" do
      const_with(expr) = Parser.parse("const foo = packed struct{};").code
      assert {:struct, %{packed: true}, _} = expr
    end

    test "can have a one line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = struct{
          //! this is a comment
        };
        """).code

      assert {:struct, %{doc_comment: " this is a comment\n"}, _} = expr
    end

    test "can have a multi line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = struct{
          //! this is a comment
          //! this is also a comment
        };
        """).code

      assert {:struct, %{doc_comment: " this is a comment\n this is also a comment\n"}, _} = expr
    end
  end

  describe "opaque container decl" do
    test "can be parsed" do
      const_with(expr) = Parser.parse("const foo = opaque{};").code
      assert {:opaque, %{extern: false, packed: false}, _} = expr
    end

    test "can be extern" do
      const_with(expr) = Parser.parse("const foo = extern opaque{};").code
      assert {:opaque, %{extern: true}, _} = expr
    end

    test "can be packed" do
      const_with(expr) = Parser.parse("const foo = packed opaque{};").code
      assert {:opaque, %{packed: true}, _} = expr
    end

    test "can have a one line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = opaque{
          //! this is a comment
        };
        """).code

      assert {:opaque, %{doc_comment: " this is a comment\n"}, _} = expr
    end

    test "can have a multi line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = opaque{
          //! this is a comment
          //! this is also a comment
        };
        """).code

      assert {:opaque, %{doc_comment: " this is a comment\n this is also a comment\n"}, _} = expr
    end
  end

  describe "enum container decl" do
    test "can be parsed" do
      const_with(expr) = Parser.parse("const foo = enum{};").code
      assert {:enum, %{extern: false, packed: false, type: nil}, _} = expr
    end

    test "can be extern" do
      const_with(expr) = Parser.parse("const foo = extern enum{};").code
      assert {:enum, %{extern: true}, _} = expr
    end

    test "can be packed" do
      const_with(expr) = Parser.parse("const foo = packed enum{};").code
      assert {:enum, %{packed: true}, _} = expr
    end

    test "can be typed" do
      const_with(expr) = Parser.parse("const foo = packed enum(u8) {};").code
      assert {:enum, %{packed: true, type: :u8}, _} = expr
    end

    test "can have a one line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = enum{
          //! this is a comment
        };
        """).code

      assert {:enum, %{doc_comment: " this is a comment\n"}, _} = expr
    end

    test "can have a multi line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = enum{
          //! this is a comment
          //! this is also a comment
        };
        """).code

      assert {:enum, %{doc_comment: " this is a comment\n this is also a comment\n"}, _} = expr
    end
  end

  describe "union container decl" do
    test "can be parsed" do
      const_with(expr) = Parser.parse("const foo = union{};").code
      assert {:union, %{extern: false, packed: false, tagtype: nil}, _} = expr
    end

    test "can be extern" do
      const_with(expr) = Parser.parse("const foo = extern union{};").code
      assert {:union, %{extern: true}, _} = expr
    end

    test "can be packed" do
      const_with(expr) = Parser.parse("const foo = packed union{};").code
      assert {:union, %{packed: true}, _} = expr
    end

    test "can be typed" do
      const_with(expr) = Parser.parse("const foo = packed union(my_enum) {};").code

      assert {:union, %{packed: true, tagtype: :my_enum}, _} = expr
    end

    test "can have an inferred enum type" do
      const_with(expr) = Parser.parse("const foo = packed union(enum) {};").code
      assert {:union, %{packed: true, tagtype: nil, tagged: true}, _} = expr
    end

    test "can have a backed, inferred enum type" do
      const_with(expr) = Parser.parse("const foo = packed union(enum(u8)) {};").code

      assert {:union, %{packed: true, tagtype: {:enum, :u8}, tagged: true}, _} = expr
    end

    test "can have a one line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = union{
          //! this is a comment
        };
        """).code

      assert {:union, %{doc_comment: " this is a comment\n"}, _} = expr
    end

    test "can have a multi line doc comment" do
      const_with(expr) =
        Parser.parse("""
        const foo = union{
          //! this is a comment
          //! this is also a comment
        };
        """).code

      assert {:union, %{doc_comment: " this is a comment\n this is also a comment\n"}, _} = expr
    end
  end

  describe "a struct container" do
    test "can have a single field" do
      const_with(expr) = Parser.parse("const foo = struct{x: i8};").code
      assert {:struct, _, parts} = expr
      assert [x: :i8] = Keyword.get(parts, :fields)
    end

    test "can have multiple fields" do
      const_with(expr) = Parser.parse("const foo = struct{x: i8, y: f32};").code
      assert {:struct, _, parts} = expr
      assert [x: :i8, y: :f32] = Keyword.get(parts, :fields)
    end

    test "can have a const decl" do
      const_with(expr) = Parser.parse("const foo = struct{const x = 100;};").code
      assert {:struct, _, parts} = expr
      assert [{:const, _, {:x, _, _}}] = Keyword.get(parts, :decls)
    end
  end

  describe "an enum container" do
    test "can have a single field" do
      const_with(expr) = Parser.parse("const foo = enum{foo};").code
      assert {:enum, _, parts} = expr
      assert [:foo] = Keyword.get(parts, :fields)
    end

    test "can have multiple fields" do
      const_with(expr) = Parser.parse("const foo = enum{foo, bar};").code
      assert {:enum, _, parts} = expr
      assert [:foo, :bar] = Keyword.get(parts, :fields)
    end

    test "can have a const decl" do
      const_with(expr) = Parser.parse("const foo = enum{const x = 100;};").code
      assert {:enum, _, parts} = expr
      assert [{:const, _, {:x, _, _}}] = Keyword.get(parts, :decls)
    end
  end
end
