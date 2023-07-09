defmodule Zig.Parser.ParseError do
  defexception [:message, :remainder, :context, :line, :column]
end
