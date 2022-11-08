defmodule Zig.Parser.Test.ExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # tests:
  # PrimaryExpr
  #    <- AsmExpr
  #     / IfExpr
  #     / KEYWORD_break BreakLabel? Expr?
  #     / KEYWORD_comptime Expr
  #     / KEYWORD_nosuspend Expr
  #     / KEYWORD_continue BreakLabel?
  #     / KEYWORD_resume Expr
  #     / KEYWORD_return Expr?
  #     / BlockLabel? LoopExpr # <-- punted to LoopTest
  #     / Block
  #     / CurlySuffixExpr

  describe "asm expressions" do
    # AsmExpr <- KEYWORD_asm KEYWORD_volatile? LPAREN Expr AsmOutput? RPAREN
    # AsmOutput <- COLON AsmOutputList AsmInput?
    # AsmOutputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN (MINUSRARROW TypeExpr / IDENTIFIER) RPAREN
    # AsmOutputList <- (AsmOutputItem COMMA)* AsmOutputItem?
    # AsmInput <- COLON AsmInputList AsmClobbers?
    # AsmInputList <- (AsmInputItem COMMA)* AsmInputItem?
    # AsmInputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN Expr RPAREN
    # AsmClobbers <- COLON StringList

    defmacrop asm_with(
                parts,
                opts \\ quote do
                  %{}
                end
              ) do
      quote do
        [{:const, _, {:foo, _, {:asm, unquote(opts), unquote(parts)}}}]
      end
    end

    test "basic asm expression" do
      assert asm_with(expr: {:string, "syscall"}, outputs: [], inputs: [], clobbers: []) =
               Parser.parse(~S|const foo = asm("syscall" : : : );|).code
    end

    test "asm with volatile" do
      assert asm_with(_, %{volatile: true}) =
               Parser.parse(~S|const foo = asm volatile("syscall" : : : );|).code
    end

    test "one output expression" do
      asm_with(parts) =
        Parser.parse(~S|const foo = asm("syscall" : [ret] "={rax}" (-> usize) : : );|).code

      assert [{:ret, "={rax}", {:->, :usize}}] = parts[:outputs]
    end

    test "one output expression with an identifier" do
      asm_with(parts) =
        Parser.parse(~S|const foo = asm("syscall" : [ret] "={rax}" (identifier) : : );|).code

      assert [{:ret, "={rax}", :identifier}] = parts[:outputs]
    end

    test "two output expressions" do
      asm_with(parts) =
        Parser.parse(
          ~S|const foo = asm("syscall" : [ret] "={rax}" (-> usize), [ret] "={rax}" (-> usize) : : );|
        ).code

      assert [{:ret, "={rax}", {:->, :usize}}, {:ret, "={rax}", {:->, :usize}}] = parts[:outputs]
    end

    test "one input expression" do
      asm_with(parts) =
        Parser.parse(~S|const foo = asm("syscall" : : [number] "{rax}" (number) : );|).code

      assert [{:number, "{rax}", :number}] = parts[:inputs]
    end

    test "two input expressions" do
      asm_with(parts) =
        Parser.parse(
          ~S|const foo = asm("syscall" : : [number] "{rax}" (number), [arg1] "{rdi}" (arg1) : );|
        ).code

      assert [{:number, "{rax}", :number}, {:arg1, "{rdi}", :arg1}] = parts[:inputs]
    end

    test "one clobber register" do
      asm_with(parts) = Parser.parse(~S|const foo = asm("syscall" : : : "rcx");|).code
      assert ["rcx"] = parts[:clobbers]
    end

    test "two clobber registers" do
      asm_with(parts) = Parser.parse(~S|const foo = asm("syscall" : : : "rcx", "r11");|).code
      assert ["rcx", "r11"] = parts[:clobbers]
    end

    test "with multiline string" do
      asm_with(parts) =
        Parser.parse(~S"""
        const foo = asm(
          \\ this is
          \\ some
          \\ assembler code
          : : : );
        """).code

      assert {:string, " this is\n some\n assembler code\n"} = parts[:expr]
    end
  end

  defmacro const_with(expr) do
    quote do
      [{:const, _, {:foo, _, unquote(expr)}}]
    end
  end

  describe "if expr" do
    # IfExpr <- IfPrefix Expr (KEYWORD_else Payload? Expr)?
    # IfPrefix <- KEYWORD_if LPAREN Expr RPAREN PtrPayload?

    test "basic if statement only" do
      assert const_with({:if, _, condition: :foo, consequence: :bar}) =
               Parser.parse("const foo = if (foo) bar;").code
    end

    test "basic if statement with payload paramater" do
      assert const_with({:if, _, condition: :foo, payload: :bar, consequence: :bar}) =
               Parser.parse("const foo = if (foo) |bar| bar;").code
    end

    test "basic if statement with pointer payload parameter" do
      assert const_with({:if, _, condition: :foo, ptr_payload: :bar, consequence: :bar}) =
               Parser.parse("const foo = if (foo) |*bar| bar;").code
    end

    test "basic else statement" do
      assert const_with({:if, _, condition: :foo, consequence: :bar, else: :baz}) =
               Parser.parse("const foo = if (foo) bar else baz;").code
    end

    test "else statement with payload" do
      assert const_with(
               {:if, _, condition: :foo, consequence: :bar, else_payload: :baz, else: :baz}
             ) = Parser.parse("const foo = if (foo) bar else |baz| baz;").code
    end
  end

  describe "break/continue expr" do
    # note these are a misuse of the const and are probably a semantic error.
    test "break" do
      assert const_with(:break) = Parser.parse("const foo = break;").code
    end

    test "break with tag" do
      assert const_with({:break, :foo}) = Parser.parse("const foo = break :foo;").code
    end

    test "break with tag and value" do
      assert const_with({:break, :foo, :bar}) = Parser.parse("const foo = break :foo bar;").code
    end

    test "continue" do
      assert const_with(:continue) = Parser.parse("const foo = continue;").code
    end

    test "continue with tag" do
      assert const_with({:continue, :foo}) = Parser.parse("const foo = continue :foo;").code
    end
  end

  describe "tagged exprs" do
    test "comptime" do
      assert const_with({:comptime, :bar}) = Parser.parse("const foo = comptime bar;").code
    end

    test "nosuspend" do
      assert const_with({:nosuspend, :bar}) = Parser.parse("const foo = nosuspend bar;").code
    end

    test "resume" do
      assert const_with({:resume, :bar}) = Parser.parse("const foo = resume bar;").code
    end

    test "return" do
      assert const_with({:return, :bar}) = Parser.parse("const foo = return bar;").code
    end
  end

  describe "blocks" do
    # note this is probably a semantic error
    test "work" do
      assert const_with({:block, _, []}) = Parser.parse("const foo = {};").code
    end
  end

  describe "curly suffix init" do
    test "with an empty curly struct" do
      assert const_with({:empty, :MyStruct}) = Parser.parse("const foo = MyStruct{};").code
    end

    test "with a struct definer" do
      assert const_with({:struct, :MyStruct, %{foo: {:integer, 1}}}) =
               Parser.parse("const foo = MyStruct{.foo = 1};").code
    end

    test "with a struct definer with two terms" do
      assert const_with({:struct, :MyStruct, %{foo: {:integer, 1}, bar: {:integer, 2}}}) =
               Parser.parse("const foo = MyStruct{.foo = 1, .bar = 2};").code
    end

    test "with an array definer" do
      assert const_with({:array, :MyArrayType, [integer: 1, integer: 2, integer: 3]}) =
               Parser.parse("const foo = MyArrayType{1, 2, 3};").code
    end
  end
end
