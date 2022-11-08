defmodule Zig.Parser.Test.PrimaryTypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  alias Zig.Parser

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

  defmacrop const_with(expr) do
    quote do
      [{:const, _, {_, _, unquote(expr)}}]
    end
  end

  describe "builtin function" do
    test "with no arguments" do
      assert const_with(expr) = Parser.parse("const foo = @builtin_fn();").code

      assert {:builtin, :builtin_fn, []} = expr
    end

    test "with one arguments" do
      assert const_with(expr) = Parser.parse("const foo = @builtin_fn(foo);").code

      assert {:builtin, :builtin_fn, [:foo]} = expr
    end

    test "with two arguments" do
      assert const_with(expr) = Parser.parse("const foo = @builtin_fn(foo, bar);").code

      assert {:builtin, :builtin_fn, [:foo, :bar]} = expr
    end
  end

  describe "char literal" do
    test "basic ascii" do
      assert const_with(?a) = Parser.parse("const foo = 'a';").code
    end

    @tag :skip
    test "utf-8 literal" do
      assert const_with(?🚀) = Parser.parse("const foo = '🚀';").code
    end

    test "escaped char" do
      assert const_with(?\t) = Parser.parse("const foo = '\\t';").code
    end

    test "escaped hex" do
      assert const_with(?🚀) = Parser.parse("const foo = '\\u{1F680}';").code
    end
  end

  describe "container decl" do
    # see container_decl_test.exs
  end

  describe "enum literal" do
    test "is parsed" do
      assert const_with({:enum_literal, :foo}) = Parser.parse("const foo = .foo;").code
    end
  end

  describe "initlist" do
    test "for anonymous struct with one item" do
      assert const_with({:anonymous_struct, %{foo: :bar}}) =
               Parser.parse("const foo = .{.foo = bar};").code
    end

    test "for anonymous struct with more items" do
      assert const_with({:anonymous_struct, %{foo: :bar, bar: :baz}}) =
               Parser.parse("const foo = .{.foo = bar, .bar = baz};").code
    end

    test "for tuple with one item" do
      assert const_with({:tuple, [:foo]}) = Parser.parse("const foo = .{foo};").code
    end

    test "for tuple with more than one item" do
      assert const_with({:tuple, [:foo, :bar]}) = Parser.parse("const foo = .{foo, bar};").code
    end

    test "for empty tuple" do
      assert const_with({:empty}) = Parser.parse("const foo = .{};").code
    end
  end

  describe "errorsetdecl" do
    test "with one error" do
      assert const_with({:errorset, [:abc]}) = Parser.parse("const foo = error {abc};").code
    end

    test "with more than one error" do
      assert const_with({:errorset, [:abc, :bcd]}) =
               Parser.parse("const foo = error {abc, bcd};").code
    end
  end

  describe "literals" do
    test "float" do
      assert const_with({:float, 4.7}) = Parser.parse("const foo = 4.7;").code
    end

    test "integer" do
      assert const_with({:integer, 47}) = Parser.parse("const foo = 47;").code
    end

    test "string" do
      assert const_with({:string, "literal"}) = Parser.parse(~S(const foo = "literal";)).code
    end

    test "error" do
      assert const_with({:error, :foo}) = Parser.parse(~S(const foo = error.foo;)).code
    end
  end

  describe "fnproto" do
    test "works with no parameters" do
      const_with({:fn, _, parts}) = Parser.parse("const foo = fn () void;").code
      assert [] = parts[:params]
      assert :void = parts[:type]
    end

    test "works with one parameter" do
      const_with({:fn, _, parts}) = Parser.parse("const foo = fn (u8) void;").code
      assert [{:_, _, :u8}] = parts[:params]
      assert :void = parts[:type]
    end

    test "works with one named parameter" do
      const_with({:fn, _, parts}) = Parser.parse("const foo = fn (this: u8) void;").code
      assert [{:this, _, :u8}] = parts[:params]
      assert :void = parts[:type]
    end

    test "works with two parameters" do
      const_with({:fn, _, parts}) = Parser.parse("const foo = fn (u8, u32) void;").code
      assert [{:_, _, :u8}, {:_, _, :u32}] = parts[:params]
      assert :void = parts[:type]
    end
  end

  describe "GroupedExpr" do
    test "drops parentheses" do
      assert const_with(:void) = Parser.parse("const foo = (void);").code
    end
  end

  describe "LabeledTypeExpr" do
    test "can be a labeled block" do
      const_with(expr) = Parser.parse("const foo = label: {};").code
      assert {:block, %{label: :label}, []} = expr
    end

    test "can be a labeled loop" do
      const_with(expr) = Parser.parse("const foo = label: while (true) {};").code
      assert {:while, %{label: :label}, _} = expr
    end
  end

  describe "identifier" do
    test "can be a basic identifier" do
      assert const_with(:identifier) = Parser.parse("const foo = identifier;").code
    end

    test "can be a an identifier with special string" do
      assert const_with(:"foo-bar") = Parser.parse(~S(const foo = @"foo-bar";)).code
    end

    @tag :skip
    test "can be a an identifier with really special string" do
      assert const_with(:"🚀") = Parser.parse(~S(const foo = @"🚀";)).code
    end
  end

  describe "iftypeexpr" do
    test "can be parsed" do
      assert const_with({:if, _, _}) = Parser.parse("const foo = if (true) bar;").code
    end
  end

  describe "comptime" do
    test "can be parsed" do
      assert const_with({:comptime, _}) = Parser.parse("const foo = comptime {};").code
    end
  end

  describe "special literals" do
    test "anyframe" do
      assert const_with(:anyframe) = Parser.parse("const foo = anyframe;").code
    end

    test "unreachable" do
      assert const_with(:unreachable) = Parser.parse("const foo = unreachable;").code
    end
  end

  describe "switch" do
    test "switch" do
      assert const_with({:switch, _, _}) = Parser.parse("const foo = switch (bar) {};").code
    end
  end
end
