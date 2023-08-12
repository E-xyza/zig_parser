defmodule Zig.Parser.Continue do
  defstruct [:label]

  def parse([:COLON, label]) do
    %__MODULE__{label: label}
  end

  def parse([]) do
    %__MODULE__{}
  end
end
