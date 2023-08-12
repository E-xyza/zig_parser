defmodule Zig.Parser.Struct do
  defstruct [:location, packed: false, extern: false, decls: %{}, fields: %{}]

  def parse([:LBRACE | rest]), do: do_parse(rest, %__MODULE__{})

  defp do_parse([:RBRACE], struct), do: struct
end
