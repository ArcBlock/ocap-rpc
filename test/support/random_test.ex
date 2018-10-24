defmodule OcapRpcTest.RandomTest do
  @moduledoc false

  alias OcapRpc.Eth.Block

  def run(limit) do
    height =
      limit
      |> :rand.uniform()
      |> Hexate.encode()

    IO.puts("Querying block #{"0x" <> height}")
    Block.get_by_number("0x" <> height, true)
    run(limit)
  end
end
