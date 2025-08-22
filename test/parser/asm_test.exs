defmodule Zig.Parser.AsmTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Asm

  describe "asm expressions" do
    # AsmExpr <- KEYWORD_asm KEYWORD_volatile? LPAREN Expr AsmOutput? RPAREN
    # AsmOutput <- COLON AsmOutputList AsmInput?
    # AsmOutputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN (MINUSRARROW TypeExpr / IDENTIFIER) RPAREN
    # AsmOutputList <- (AsmOutputItem COMMA)* AsmOutputItem?
    # AsmInput <- COLON AsmInputList AsmClobbers?
    # AsmInputList <- (AsmInputItem COMMA)* AsmInputItem?
    # AsmInputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN Expr RPAREN
    # AsmClobbers <- COLON PrimaryTypeExpression

    test "basic asm expression" do
      assert [%{value: %Asm{code: {:string, "syscall"}}}] =
               Parser.parse(~S|const foo = asm("syscall" : : : .{});|).code
    end

    test "asm expression location" do
      assert [_, %{value: %Asm{location: location}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = asm("syscall" : : : .{});
               """).code

      assert {2, 13} == location
    end

    test "asm with volatile" do
      assert [%{value: %Asm{volatile: true}}] =
               Parser.parse(~S|const foo = asm volatile("syscall" : : : .{});|).code
    end

    test "one output expression" do
      assert [%{value: %Asm{outputs: [{:ret, "={rax}", type: :usize}]}}] =
               Parser.parse(~S|const foo = asm("syscall" : [ret] "={rax}" (-> usize) : : .{});|).code
    end

    test "one output expression with an identifier" do
      assert [%{value: %Asm{outputs: [{:ret, "={rax}", var: :identifier}]}}] =
               Parser.parse(~S|const foo = asm("syscall" : [ret] "={rax}" (identifier) : : .{});|).code
    end

    test "two output expressions" do
      # Note that this is not currently supported by zig but allowed in the parser.
      assert [
               %{
                 value: %Asm{
                   outputs: [{:ret, "={rax}", type: :usize}, {:ret, "={rax}", type: :usize}]
                 }
               }
             ] =
               Parser.parse(
                 ~S|const foo = asm("syscall" : [ret] "={rax}" (-> usize), [ret] "={rax}" (-> usize) : : .{});|
               ).code
    end

    test "one input expression" do
      assert [%{value: %Asm{inputs: [{:number, "{rax}", var: :number}]}}] =
               Parser.parse(~S|const foo = asm("syscall" : : [number] "{rax}" (number) : .{});|).code
    end

    test "two input expressions" do
      assert [
               %{
                 value: %Asm{
                   inputs: [{:number, "{rax}", var: :number}, {:arg1, "{rdi}", var: :arg1}]
                 }
               }
             ] =
               Parser.parse(
                 ~S|const foo = asm("syscall" : : [number] "{rax}" (number), [arg1] "{rdi}" (arg1) : .{});|
               ).code
    end

    test "one clobber register" do
      assert [%{value: %Asm{clobbers: %{values: %{rcx: true}}}}] =
               Parser.parse(~S|const foo = asm("syscall" : : : .{.rcx = true});|).code
    end

    test "two clobber registers" do
      assert [%{value: %Asm{clobbers: %{values: %{rcx: true, r11: true}}}}] =
               Parser.parse(~S|const foo = asm("syscall" : : : .{.rcx = true, .r11 = true});|).code
    end

    test "with multiline string" do
      assert [%{value: %Asm{code: {:string, code}}}] =
               Parser.parse(~S"""
               const foo = asm(
                 \\ this is
                 \\ some
                 \\ assembler code
                 : : : .{});
               """).code

      assert code == " this is\n some\n assembler code\n"
    end
  end

  describe "degenerate asm segments" do
    test "just the asm" do
      assert [_] =
               Parser.parse(~S"""
               const foo =
                 asm (
                   \\.globl this_is_my_alias;
                 );
               """).code
    end
  end
end
