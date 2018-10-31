defmodule OcapRpc.Internal do
  @moduledoc """
  Generate the code for RPC library.
  """
  alias OcapRpc.Internal.{CodeGen, Parser}
  path = Path.join(File.cwd!(), "priv/gen")

  [:btc, :eth, :ipfs]
  |> Enum.flat_map(fn type ->
    data = Parser.read_main(type)

    Enum.map(data["result"], fn {name, fields} ->
      CodeGen.gen_type(name, fields, type, path: Path.join(path, "type"))
    end)

    Enum.map(data["rpc"], &CodeGen.gen(&1, data["result"], type, path: Path.join(path, "rpc")))
  end)
end
