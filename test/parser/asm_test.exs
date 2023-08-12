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
    # AsmClobbers <- COLON StringList

    test "basic asm expression" do
      assert [%{value: %Asm{code: "syscall"}}] =
               Parser.parse(~S|const foo = asm("syscall" : : : );|).code
    end

    test "asm with volatile" do
      assert [%{value: %Asm{volatile: true}}] =
               Parser.parse(~S|const foo = asm volatile("syscall" : : : );|).code
    end

    test "one output expression" do
      assert [%{value: %Asm{outputs: [{:ret, "={rax}", type: :usize}]}}] =
               Parser.parse(~S|const foo = asm("syscall" : [ret] "={rax}" (-> usize) : : );|).code
    end

    test "one output expression with an identifier" do
      assert [%{value: %Asm{outputs: [{:ret, "={rax}", var: :identifier}]}}] =
               Parser.parse(~S|const foo = asm("syscall" : [ret] "={rax}" (identifier) : : );|).code
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
                 ~S|const foo = asm("syscall" : [ret] "={rax}" (-> usize), [ret] "={rax}" (-> usize) : : );|
               ).code
    end

    test "one input expression" do
      assert [%{value: %Asm{inputs: [{:number, "{rax}", var: :number}]}}] =
               Parser.parse(~S|const foo = asm("syscall" : : [number] "{rax}" (number) : );|).code
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
                 ~S|const foo = asm("syscall" : : [number] "{rax}" (number), [arg1] "{rdi}" (arg1) : );|
               ).code
    end

    test "one clobber register" do
      assert [%{value: %Asm{clobbers: ["rcx"]}}] =
               Parser.parse(~S|const foo = asm("syscall" : : : "rcx");|).code
    end

    test "two clobber registers" do
      assert [%{value: %Asm{clobbers: ["rcx", "r11"]}}] =
               Parser.parse(~S|const foo = asm("syscall" : : : "rcx", "r11");|).code
    end

    test "with multiline string" do
      assert [%{value: %Asm{code: code}}] =
               Parser.parse(~S"""
               const foo = asm(
                 \\ this is
                 \\ some
                 \\ assembler code
                 : : : );
               """).code

      assert code == " this is\n some\n assembler code\n"
    end
  end
end
