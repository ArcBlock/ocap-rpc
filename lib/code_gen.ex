defmodule OcapRpc.Internal do
  @moduledoc """
  Generate the code for RPC library.
  """
  alias OcapRpc.Internal.{CodeGen, Parser}
  path = Path.join(File.cwd!(), "priv/gen")

  # [:btc, :eth]
  # |> Enum.flat_map(fn token ->
  #   token
  #   |> Parser.read_main()
  #   |> Enum.map(&CodeGen.gen(&1, :eth, path: Path.join(path, "rpc")))
  # end)
end
