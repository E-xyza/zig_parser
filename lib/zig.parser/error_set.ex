defmodule Zig.Parser.ErrorSet do
  defstruct [:values, :location]

  @terminators [[], [:COMMA]]

  def parse([:LBRACE, {:IdentifierList, list}, :RBRACE]) do
    parse(list, [])
  end

  defp parse([], []), do: %__MODULE__{values: []}

  defp parse([identifier | terminator], so_far) when terminator in @terminators do
    %__MODULE__{values: Enum.reverse([identifier | so_far])}
  end

  defp parse([identifier, :COMMA | rest], so_far) do
    parse(rest, [identifier | so_far])
  end
end
