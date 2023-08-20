defmodule Zig.Parser.Switch do
  defstruct [:subject, :prongs]

  def parse([:switch, :LPAREN, subject, :RPAREN, :LBRACE, {:SwitchProngList, prongs}, :RBRACE]) do
    %__MODULE__{subject: subject, prongs: prongs}
  end
end
