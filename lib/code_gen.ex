defmodule BlockchainRpc.Internal.CodeGen do
  @moduledoc """
  Generate the code for RPC library.
  """
  alias BlockchainRpc.Internal.{EthCode, Parser}
  path = Path.join(File.cwd!(), "priv/gen")

  :eth
  |> Parser.get_data()
  |> Enum.map(&EthCode.gen(&1, :eth, path: Path.join(path, "rpc")))
end
