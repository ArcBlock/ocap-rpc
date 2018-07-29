defmodule OcapRpcTest.EthChain do
  use ExUnit.Case
  import Mock
  import OcapRpcTest.MockHttp

  alias OcapRpc.Converter
  alias OcapRpc.Eth.Chain
  alias OcapRpcTest.TestUtils

  test "Should return current block of the chain" do
    with_mock(HTTPoison, post: &post/4) do
      assert Chain.current_block() == TestUtils.block_height() |> Converter.to_int()
    end
  end

  test "Should return current gas price of the chain" do
    with_mock(HTTPoison, post: &post/4) do
      assert Chain.gas_price() == TestUtils.gas_price() |> Converter.to_int()
    end
  end
end
