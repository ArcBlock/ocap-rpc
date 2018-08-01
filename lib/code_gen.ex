defmodule OcapRpc.Internal do
  @moduledoc """
  Generate the code for RPC library.
  """
  alias OcapRpc.Internal.{CodeGen, Parser}
  path = Path.join(File.cwd!(), "priv/gen")

  [:btc, :eth]
  |> Enum.flat_map(fn token ->
    data = Parser.read_main(token)

    data["rpc"]
    |> Enum.map(&CodeGen.gen(&1, data["result"], token, path: Path.join(path, "rpc")))
  end)
end
