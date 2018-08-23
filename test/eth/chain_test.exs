defmodule OcapRpcTest.EthChain do
  use ExUnit.Case
  import Tesla.Mock

  alias OcapRpc.Converter
  alias OcapRpc.Eth.Chain

  alias OcapRpcTest.MockHttp
  alias OcapRpcTest.TestUtils

  setup do
    mock(fn %{method: :post, body: body} ->
      json(MockHttp.post(body))
    end)

    :ok
  end

  test "Should return current block of the chain" do
    assert Chain.current_block() == TestUtils.block_height() |> Converter.to_int()
  end

  test "Should return current gas price of the chain" do
    assert Chain.gas_price() == TestUtils.gas_price() |> Converter.to_int()
  end
end
