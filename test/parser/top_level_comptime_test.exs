defmodule Zig.Parser.Test.TopLevelComptimeTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  describe "when given a basic comptime block" do
    test "it can be found" do
      assert [{:comptime, _, {:block, %{doc_comment: nil}, []}}] =
               Parser.parse("comptime {}").code
    end

    test "doc comments are attached" do
      assert [{:comptime, _, {:block, %{doc_comment: " this does something\n"}, []}}] =
               Parser.parse("""
               /// this does something
               comptime {}
               """).code
    end
  end
end
