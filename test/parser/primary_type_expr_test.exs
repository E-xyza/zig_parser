defmodule Zig.Parser.Test.PrimaryTypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.ErrorSet
  alias Zig.Parser.Function
  alias Zig.Parser.If
  alias Zig.Parser.StructLiteral
  alias Zig.Parser.Switch

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

    test "with more than one error" do
      assert [%{value: %ErrorSet{values: [:abc, :bcd]}}] =
               Parser.parse("const foo = error {abc, bcd};").code
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
      assert [%{value: :"foo-bar"}] = Parser.parse(~S(const foo = @"foo-bar";)).code
    end

    test "can be a an identifier with really special string" do
      assert [%{value: :"🚀"}] = Parser.parse(~S(const foo = @"🚀";)).code
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
end
