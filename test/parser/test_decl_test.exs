defmodule Zig.Parser.Test.TestDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.TestDecl

  describe "the testdecl Parser.parse can" do
    test "parse an unnamed test" do
      assert %Parser{
               tests: [
                 %TestDecl{
                   name: nil,
                   block: {:block, _, []},
                   line: 1,
                   column: 1
                 }
               ]
             } = Parser.parse(~S(test {}))
    end

    test "parse a named test" do
      assert %Parser{
               tests: [
                 %TestDecl{
                   name: "foobar",
                   block: {:block, _, []},
                   line: 1,
                   column: 1
                 }
               ]
             } = Parser.parse(~S(test "foobar" {}))
    end

    test "parse a test with a doc comment" do
      assert %Parser{
               tests: [
                 %TestDecl{
                   name: "foobar",
                   doc_comment: " this is a test\n",
                   line: 2,
                   column: 1
                 }
               ]
             } =
               Parser.parse("""
               /// this is a test
               test "foobar" {}
               """)
    end
  end
end
