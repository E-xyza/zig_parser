defmodule ZigParserTest.ZigTree do
  def ensure_zig_directory do
    unless File.dir?("test/_support/zig-0.14.0") do
      build_zig_directory()
    end
  end

  defp build_zig_directory do
    ensure_zig_zipfile()
    System.cmd("tar", ["xvf", "zig-0.14.0.tar.xz"], cd: "test/_support")
  end

  defp ensure_zig_zipfile do
    unless File.exists?("test/_support/zig-0.14.0.tar.xz") do
      download_zig_zipfile()
    end
  end

  defp download_zig_zipfile do
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:inets)

    headers = []
    request = {~C'https://ziglang.org/builds/zig-0.14.0.tar.xz', headers}
    http_options = [timeout: 600_000]
    options = [body_format: :binary]

    case :httpc.request(:get, request, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        File.write!("test/_support/zig-0.14.0.tar.xz", body)

      result ->
        raise "Failed to download zig with #{inspect(result)}"
    end
  end
end
