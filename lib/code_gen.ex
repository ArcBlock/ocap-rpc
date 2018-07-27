defmodule OcapRpc.Internal do
  @moduledoc """
  Generate the code for RPC library.
  """
  alias OcapRpc.Internal.{CodeGen, Parser}
  path = Path.join(File.cwd!(), "priv/gen")

  [:btc, :eth]
  |> Enum.map(fn token ->
    token
    |> Parser.get_data()
    |> Enum.map(&CodeGen.gen(&1, :eth, path: Path.join(path, "rpc")))
  end)
end
