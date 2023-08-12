defmodule Zig.Parser.Break do
  defstruct [:label, :value]

  def parse([:COLON, label, value]) do
    %__MODULE__{label: label, value: value}
  end

  def parse([:COLON, label]) do
    %__MODULE__{label: label}
  end

  def parse([]) do
    %__MODULE__{}
  end
end
