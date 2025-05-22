if match?({:unix, _}, :os.type()) do
  ZigParserTest.ZigTree.ensure_zig_directory()
end

ExUnit.start()
