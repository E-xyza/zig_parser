defmodule Zig.Parser.Test.ComptimeTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block

  describe "when given a top level comptime decl" do
    # ComptimeDecl <- KEYWORD_comptime Block

    test "it can be found" do
      assert [%Block{comptime: true, doc_comment: nil}] =
               Parser.parse("comptime {}").code
    end

    test "doc comments are attached" do
      assert [%Block{comptime: true, doc_comment: " this does something\n"}] =
               Parser.parse("""
               /// this does something
               comptime {}
               """).code
    end
  end
end
