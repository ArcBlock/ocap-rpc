defmodule OcapRpcTest.EthBlock do
  use ExUnit.Case
  import Mock
  import OcapRpcTest.MockHttp

  alias OcapRpc.Converter
  alias OcapRpc.Eth.Block
  alias OcapRpcTest.TestUtils

  test "Should return a valid block" do
    with_mock(HTTPoison, post: &post/4) do
      data = Block.get_by_hash(TestUtils.block_hash(), false)
      assert data.hash == TestUtils.block_hash()
    end
  end

  test "Should return a valid block with transactions" do
    with_mock(HTTPoison, post: &post/4) do
      data = Block.get_by_hash(TestUtils.block_hash(), true)
      assert data.hash == TestUtils.block_hash()

      [tx | _] = data.transactions
      assert tx.hash == TestUtils.tx_hash()
    end
  end

  test "Should return a valid block by its height with transactions" do
    with_mock(HTTPoison, post: &post/4) do
      data = Block.get_by_number(TestUtils.block_height(), true)
      assert data.height == TestUtils.block_height() |> Converter.to_int()

      [tx | _] = data.transactions
      assert tx.hash == TestUtils.tx_hash()
    end
  end
end
