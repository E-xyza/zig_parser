defmodule Zig.Parser.Test.ExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Asm
  alias Zig.Parser.Block
  alias Zig.Parser.Const

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

    test "basic asm expression" do
      assert %Parser{
               decls: [
                 %Const{
                   value: %Asm{
                     volatile: false,
                     expr: {:string, "syscall"},
                     outputs: [],
                     inputs: [],
                     clobbers: []
                   }
                 }
               ]
             } = Parser.parse(~S|const foo = asm("syscall" : : : );|)
    end

    test "one output expression" do
      assert %Parser{decls: [%Const{value: %Asm{outputs: [{:ret, "={rax}", :usize}]}}]} =
               Parser.parse(
                 ~S|const foo = asm volatile("syscall" : [ret] "={rax}" (-> usize) : : );|
               )
    end

    test "one output expression with an identifier" do
      assert %Parser{decls: [%Const{value: %Asm{outputs: [{:ret, "={rax}", :identifier}]}}]} =
               Parser.parse(
                 ~S|const foo = asm volatile("syscall" : [ret] "={rax}" (identifier) : : );|
               )
    end

    test "two output expressions" do
      assert %Parser{
               decls: [
                 %Const{
                   value: %Asm{
                     outputs: [
                       {:ret, "={rax}", :usize},
                       {:ret, "={rax}", :usize}
                     ]
                   }
                 }
               ]
             } =
               Parser.parse(
                 ~S|const foo = asm volatile("syscall" : [ret] "={rax}" (-> usize), [ret] "={rax}" (-> usize) : : );|
               )
    end

    test "one input expression" do
      assert %Parser{
               decls: [%Const{value: %Asm{inputs: [{:number, "{rax}", :number}]}}]
             } =
               Parser.parse(
                 ~S|const foo = asm volatile("syscall" : : [number] "{rax}" (number) : );|
               )
    end

    test "two input expressions" do
      assert %Parser{
               decls: [
                 %Const{
                   value: %Asm{
                     inputs: [
                       {:number, "{rax}", :number},
                       {:arg1, "{rdi}", :arg1}
                     ]
                   }
                 }
               ]
             } =
               Parser.parse(
                 ~S|const foo = asm volatile("syscall" : : [number] "{rax}" (number), [arg1] "{rdi}" (arg1) : );|
               )
    end

    test "one clobber register" do
      assert %Parser{decls: [%Const{value: %Asm{clobbers: ["rcx"]}}]} =
               Parser.parse(~S|const foo = asm volatile("syscall" : : : "rcx");|)
    end

    test "two clobber registers" do
      assert %Parser{decls: [%Const{value: %Asm{clobbers: ["rcx", "r11"]}}]} =
               Parser.parse(~S|const foo = asm volatile("syscall" : : : "rcx", "r11");|)
    end

    test "with multiline string"
  end

  describe "if expr" do
    # IfExpr <- IfPrefix Expr (KEYWORD_else Payload? Expr)?
    # IfPrefix <- KEYWORD_if LPAREN Expr RPAREN PtrPayload?

    test "basic if statement only" do
      assert %Parser{decls: [%Const{value: {:if, :foo, :bar}}]} =
               Parser.parse("const foo = if (foo) bar;")
    end

    test "basic if statement with payload paramater" do
      assert %Parser{
               decls: [%Const{value: {:if, :foo, {:payload, :bar, :bar}}}]
             } = Parser.parse("const foo = if (foo) |bar| bar;")
    end

    test "basic if statement with pointer payload paramater" do
      assert %Parser{
               decls: [
                 %Const{value: {:if, :foo, {:ptr_payload, :bar, :bar}}}
               ]
             } = Parser.parse("const foo = if (foo) |*bar| bar;")
    end

    test "basic else statement" do
      assert %Parser{
               decls: [%Const{value: {:if, :foo, :bar, :baz}}]
             } = Parser.parse("const foo = if (foo) bar else baz;")
    end

    test "else statement with payload" do
      assert %Parser{
               decls: [
                 %Const{
                   value: {:if, :foo, :bar, {:payload, :baz, :baz}}
                 }
               ]
             } = Parser.parse("const foo = if (foo) bar else |baz| baz;")
    end
  end

  describe "break/continue expr" do
    # note these are a misuse of the const and are probably a semantic error.
    test "break" do
      assert %Parser{decls: [%Const{value: :break}]} = Parser.parse("const foo = break;")
    end

    test "break with tag" do
      assert %Parser{decls: [%Const{value: {:break, :foo}}]} =
               Parser.parse("const foo = break :foo;")
    end

    test "break with tag and value" do
      assert %Parser{decls: [%Const{value: {:break, :foo, :bar}}]} =
               Parser.parse("const foo = break :foo bar;")
    end

    test "continue" do
      assert %Parser{decls: [%Const{value: :continue}]} = Parser.parse("const foo = continue;")
    end

    test "continue with tag" do
      assert %Parser{decls: [%Const{value: {:continue, :foo}}]} =
               Parser.parse("const foo = continue :foo;")
    end
  end

  describe "tagged exprs" do
    test "comptime" do
      assert %Parser{decls: [%Const{value: {:comptime, :bar}}]} =
               Parser.parse("const foo = comptime bar;")
    end

    test "nosuspend" do
      assert %Parser{decls: [%Const{value: {:nosuspend, :bar}}]} =
               Parser.parse("const foo = nosuspend bar;")
    end

    test "resume" do
      assert %Parser{decls: [%Const{value: {:resume, :bar}}]} =
               Parser.parse("const foo = resume bar;")
    end

    test "return" do
      assert %Parser{decls: [%Const{value: {:return, :bar}}]} =
               Parser.parse("const foo = return bar;")
    end
  end

  describe "blocks" do
    # note this is probably a semantic error
    test "work" do
      assert %Parser{decls: [%Const{value: %Block{code: []}}]} = Parser.parse("const foo = {};")
    end
  end

  describe "curly suffix init" do
    test "with an empty curly struct" do
      assert %Parser{decls: [%Const{value: {:empty, :MyStruct}}]} =
               Parser.parse("const foo = MyStruct{};")
    end

    test "with a struct definer" do
      assert %Parser{
               decls: [%Const{value: {:struct, :MyStruct, %{foo: {:integer, 1}}}}]
             } = Parser.parse("const foo = MyStruct{.foo = 1};")
    end

    test "with a struct definer with two terms" do
      assert %Parser{
               decls: [
                 %Const{
                   value:
                     {:struct, :MyStruct, %{foo: {:integer, 1}, bar: {:integer, 2}}}
                 }
               ]
             } = Parser.parse("const foo = MyStruct{.foo = 1, .bar = 2};")
    end

    test "with an array definer" do
      assert %Parser{
               decls: [
                 %Const{
                   value: {:array, :MyArrayType, [integer: 1, integer: 2, integer: 3]}
                 }
               ]
             } = Parser.parse("const foo = MyArrayType{1, 2, 3};")
    end
  end
end
