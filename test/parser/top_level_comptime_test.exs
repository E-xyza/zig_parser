defmodule Zig.Parser.Test.TopLevelComptimeTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block

  describe "when given a basic comptime block" do
    test "it can be found" do
      assert %Parser{toplevelcomptime: [%Block{doc_comment: nil, code: []}]} =
               Parser.parse("comptime {}")
    end

    test "doc comments are attached" do
      assert %Parser{
               toplevelcomptime: [
                 %Block{doc_comment: " this does something\n", code: []}
               ]
             } =
               Parser.parse("""
               /// this does something
               comptime {}
               """)
    end
  end
end
