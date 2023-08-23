defmodule Zig.Parser.ErrorSet do
  defstruct [:values, :location]

  def parse([:LBRACE, {:IdentifierList, list}, :RBRACE]) do
    parse(list, [])
  end

  defp parse([identifier], so_far) do
    %__MODULE__{values: Enum.reverse([identifier | so_far])}
  end

  defp parse([identifier, :COMMA | rest], so_far) do
    parse(rest, [identifier | so_far])
  end
end
