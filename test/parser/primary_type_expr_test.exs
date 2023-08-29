defmodule Zig.Parser.Test.PrimaryTypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const
  alias Zig.Parser.Enum
  alias Zig.Parser.ErrorSet
  alias Zig.Parser.Function
  alias Zig.Parser.If
  alias Zig.Parser.Struct
  alias Zig.Parser.StructLiteral
  alias Zig.Parser.Switch
  alias Zig.Parser.Union

  # TESTS:
  #
  # PrimaryTypeExpr
  # <- BUILTINIDENTIFIER FnCallArguments
  #  / CHAR_LITERAL
  #  / ContainerDecl
  #  / DOT IDENTIFIER
  #  / DOT InitList
  #  / ErrorSetDecl
  #  / FLOAT
  #  / FnProto
  #  / GroupedExpr
  #  / LabeledTypeExpr
  #  / IDENTIFIER
  #  / IfTypeExpr
  #  / INTEGER
  #  / KEYWORD_comptime TypeExpr
  #  / KEYWORD_error DOT IDENTIFIER
  #  / KEYWORD_anyframe
  #  / KEYWORD_unreachable
  #  / STRINGLITERAL
  #  / SwitchExpr

  describe "builtin function" do
    test "with no arguments" do
      assert [%{value: {:call, :builtin_fn, []}}] =
               Parser.parse("const foo = @builtin_fn();").code
    end

    test "with one argument" do
      assert [%{value: {:call, :builtin_fn, [:foo]}}] =
               Parser.parse("const foo = @builtin_fn(foo);").code
    end

    test "with two arguments" do
      assert [%{value: {:call, :builtin_fn, [:foo, :bar]}}] =
               Parser.parse("const foo = @builtin_fn(foo, bar);").code
    end
  end

  describe "char literal" do
    test "basic ascii" do
      assert [%{value: {:char, ?a}}] = Parser.parse("const foo = 'a';").code
    end

    test "utf-8 literal" do
      assert [%{value: {:char, ?🚀}}] = Parser.parse("const foo = '🚀';").code
    end

    @tag :skip
    test "escaped char" do
      assert [%{value: {:char, ?\t}}] = Parser.parse(~S"const foo = '\n';").code
    end

    @tag :skip
    test "escaped hex" do
      assert [%{value: {:call, ?🚀}}] = Parser.parse(~S"const foo = '\u{1F680}';").code
    end
  end

  describe "enum literal" do
    test "is parsed" do
      assert [%{value: {:enum_literal, :foo}}] = Parser.parse("const foo = .foo;").code
    end
  end

  describe "initlist" do
    test "for anonymous struct with one item" do
      assert [%{value: %StructLiteral{type: nil, values: %{foo: :bar}}}] =
               Parser.parse("const foo = .{.foo = bar};").code
    end

    test "for anonymous struct with more items" do
      assert [%{value: %StructLiteral{type: nil, values: %{foo: :bar, bar: :baz}}}] =
               Parser.parse("const foo = .{.foo = bar, .bar = baz};").code
    end

    test "for tuple with one item" do
      assert [%{value: %StructLiteral{type: nil, values: %{0 => :foo}}}] =
               Parser.parse("const foo = .{foo};").code
    end

    test "for tuple with more than one item" do
      assert [%{value: %StructLiteral{type: nil, values: %{0 => :foo, 1 => :bar}}}] =
               Parser.parse("const foo = .{foo, bar};").code
    end

    test "for empty tuple" do
      empty = %{}

      assert [%{value: %StructLiteral{type: nil, values: ^empty}}] =
               Parser.parse("const foo = .{};").code
    end
  end

  describe "errorsetdecl" do
    test "with one error" do
      assert [%{value: %ErrorSet{values: [:abc]}}] =
               Parser.parse("const foo = error {abc};").code
    end

    test "trailing comma" do
      assert [%{value: %ErrorSet{values: [:abc]}}] =
               Parser.parse("const foo = error {abc,};").code
    end

    test "with more than one error" do
      assert [%{value: %ErrorSet{values: [:abc, :bcd]}}] =
               Parser.parse("const foo = error {abc, bcd};").code
    end

    test "gets the location correct" do
      assert [_, %{value: %ErrorSet{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = error {abc};
               """).code
    end
  end

  describe "literals" do
    test "float" do
      assert [%{value: {:float, 4.7}}] = Parser.parse("const foo = 4.7;").code
    end

    test "integer" do
      assert [%{value: {:integer, 47}}] = Parser.parse("const foo = 47;").code
    end

    test "string" do
      assert [%{value: {:string, "literal"}}] = Parser.parse(~S(const foo = "literal";)).code
    end

    test "error" do
      assert [%{value: {:error, :foo}}] = Parser.parse(~S(const foo = error.foo;)).code
    end
  end

  describe "fnproto" do
    test "works with no parameters" do
      assert [%{value: %Function{params: [], type: :void}}] =
               Parser.parse("const foo = fn () void;").code
    end

    test "works with one parameter" do
      assert [%{value: %Function{params: [%{type: :u8}], type: :void}}] =
               Parser.parse("const foo = fn (u8) void;").code
    end

    test "works with one named parameter" do
      assert [%{value: %Function{params: [%{name: :this}], type: :void}}] =
               Parser.parse("const foo = fn (this: u8) void;").code
    end

    test "works with two parameters" do
      assert [%{value: %Function{params: [%{type: :u8}, %{type: :u32}], type: :void}}] =
               Parser.parse("const foo = fn (u8, u32) void;").code
    end

    test "works with noalias" do
      assert [%{value: %Function{params: [%{noalias: true}], type: :void}}] =
               Parser.parse("const foo = fn (noalias u8) void;").code
    end

    test "works with comptime" do
      assert [%{value: %Function{params: [%{comptime: true}], type: :void}}] =
               Parser.parse("const foo = fn (comptime u8) void;").code
    end

    test "works with tripledot" do
      assert [%{value: %Function{params: [%{type: :...}], type: :void}}] =
               Parser.parse("const foo = fn (...) void;").code
    end
  end

  describe "GroupedExpr" do
    test "drops parentheses" do
      assert [%{value: :void}] = Parser.parse("const foo = (void);").code
    end
  end

  describe "LabeledTypeExpr" do
    test "can be a labeled block" do
      assert [%{value: %{label: :label}}] = Parser.parse("const foo = label: {};").code
    end

    test "can be a labeled loop" do
      assert [%{value: %{label: :label}}] =
               Parser.parse("const foo = label: while (true) {};").code

      assert [%{value: %{label: :label}}] =
               Parser.parse("const foo = label: for (true) |_| {};").code
    end
  end

  describe "identifier" do
    test "can be a basic identifier" do
      assert [%{value: :identifier}] = Parser.parse("const foo = identifier;").code
    end

    test "can be a an identifier with special string" do
      assert [%{value: {:builtin, :"foo-bar"}}] = Parser.parse(~S(const foo = @"foo-bar";)).code
    end

    test "can be a an identifier with really special string" do
      assert [%{value: {:builtin, :"🚀"}}] = Parser.parse(~S(const foo = @"🚀";)).code
    end
  end

  describe "IfTypeExpr" do
    test "can be parsed" do
      assert [%{value: %If{}}] = Parser.parse("const foo = if (true) bar;").code
    end
  end

  describe "comptime" do
    test "can be parsed" do
      assert [%{value: %Block{comptime: true}}] = Parser.parse("const foo = comptime {};").code
    end
  end

  describe "special literals" do
    test "anyframe" do
      assert [%{value: :anyframe}] = Parser.parse("const foo = anyframe;").code
    end

    test "unreachable" do
      assert [%{value: :unreachable}] = Parser.parse("const foo = unreachable;").code
    end
  end

  describe "switch" do
    test "switch" do
      assert [%{value: %Switch{}}] = Parser.parse("const foo = switch (bar) {};").code
    end
  end

  describe "structs" do
    test "basic structs work" do
      assert [
               %{
                 value: %Struct{
                   packed: false,
                   extern: false,
                   backed: nil
                 }
               }
             ] = Parser.parse("const foo = struct {};").code
    end

    test "integer backed structs" do
      assert [%{value: %Struct{backed: :u8}}] = Parser.parse("const foo = struct (u8) {};").code
    end

    test "packed structs work" do
      assert [%{value: %Struct{packed: true}}] =
               Parser.parse("const foo = packed struct {};").code
    end

    test "extern structs work" do
      assert [%{value: %Struct{extern: true}}] =
               Parser.parse("const foo = extern struct {};").code
    end

    test "struct const decl" do
      assert [%{value: %Struct{decls: [%Const{}]}}] =
               Parser.parse("const foo = struct { const a = .bar; };").code
    end

    test "struct fun decl" do
      assert [%{value: %Struct{decls: [%Function{}]}}] =
               Parser.parse("const foo = struct { fn a() void {} };").code
    end

    test "struct field" do
      assert [%{value: %Struct{fields: %{foo: :u8}}}] =
               Parser.parse("const foo = struct { foo: u8 };").code
    end

    test "multi field" do
      assert [%{value: %Struct{fields: %{foo: :u8, bar: :u8}}}] =
               Parser.parse("const foo = struct { foo: u8, bar: u8 };").code
    end

    test "struct field with assignment" do
      assert [%{value: %Struct{fields: %{foo: {:u8, {:integer, 10}}}}}] =
               Parser.parse("const foo = struct { foo: u8 = 10 };").code
    end

    test "get location" do
      assert [_, %{value: %Struct{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = struct {};
               """).code
    end
  end

  describe "enums" do
    test "basic enums work" do
      assert [
               %{
                 value: %Enum{
                   packed: false,
                   extern: false
                 }
               }
             ] = Parser.parse("const foo = enum {};").code
    end

    test "packed enums work" do
      assert [%{value: %Enum{packed: true}}] =
               Parser.parse("const foo = packed enum {};").code
    end

    test "extern enums work" do
      assert [%{value: %Enum{extern: true}}] =
               Parser.parse("const foo = extern enum {};").code
    end

    test "enum const decl" do
      assert [%{value: %Enum{decls: [%Const{}]}}] =
               Parser.parse("const foo = enum { const a = .bar; };").code
    end

    test "enum fun decl" do
      assert [%{value: %Enum{decls: [%Function{}]}}] =
               Parser.parse("const foo = enum { fn a() void {} };").code
    end

    test "enum field" do
      assert [%{value: %Enum{fields: [:foo]}}] =
               Parser.parse("const foo = enum { foo };").code
    end

    test "multi field" do
      assert [%{value: %Enum{fields: [:foo, :bar]}}] =
               Parser.parse("const foo = enum { foo, bar };").code
    end

    test "field with assignment" do
      assert [%{value: %Enum{fields: [{:foo, {:integer, 1}}]}}] =
               Parser.parse("const foo = enum { foo = 1 };").code
    end

    test "get location" do
      assert [_, %{value: %Enum{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = enum {};
               """).code
    end
  end

  describe "unions" do
    test "basic unions work" do
      assert [
               %{
                 value: %Union{
                   packed: false,
                   extern: false
                 }
               }
             ] = Parser.parse("const foo = union {};").code
    end

    test "packed unions work" do
      assert [%{value: %Union{packed: true}}] =
               Parser.parse("const foo = packed union {};").code
    end

    test "extern unions work" do
      assert [%{value: %Union{extern: true}}] =
               Parser.parse("const foo = extern union {};").code
    end

    test "backed unions work" do
      assert [%{value: %Union{tag: :tag_type}}] =
               Parser.parse("const foo = union(tag_type) {};").code
    end

    test "union const decl" do
      assert [%{value: %Union{decls: [%Const{}]}}] =
               Parser.parse("const foo = union { const a = .bar; };").code
    end

    test "union fun decl" do
      assert [%{value: %Union{decls: [%Function{}]}}] =
               Parser.parse("const foo = union { fn a() void {} };").code
    end

    test "union field" do
      assert [%{value: %Union{fields: %{foo: :u8}}}] =
               Parser.parse("const foo = union { foo: u8 };").code
    end

    test "multi field" do
      assert [%{value: %Union{fields: %{foo: :u8, bar: :u8}}}] =
               Parser.parse("const foo = union { foo: u8, bar: u8 };").code
    end

    test "get location" do
      assert [_, %{value: %Union{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = union {};
               """).code
    end
  end

  describe "opaque" do
    test "opaque works" do
      assert [
               %{value: :opaque}
             ] = Parser.parse("const foo = opaque {};").code
    end
  end
end
