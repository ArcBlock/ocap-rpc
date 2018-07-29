defmodule OcapRpcTest.EthTx do
  use ExUnit.Case
  import Mock
  import OcapRpcTest.MockHttp

  alias OcapRpc.Converter
  alias OcapRpc.Eth.Transaction
  alias OcapRpcTest.TestUtils

  test "Should return transaction" do
    with_mock(HTTPoison, post: &post/4) do
      data = Transaction.get_by_hash(TestUtils.tx_hash())
      assert data.hash == TestUtils.tx_hash()
    end
  end

  test "Should return transaction by block number and index" do
    with_mock(HTTPoison, post: &post/4) do
      data = Transaction.get_by_block_number_and_index(TestUtils.block_height(), 0)
      assert data.hash == TestUtils.tx_hash()
    end
  end

  test "Should return transaction by block hash and index" do
    with_mock(HTTPoison, post: &post/4) do
      data = Transaction.get_by_block_hash_and_index(TestUtils.block_hash(), 0)
      assert data.hash == TestUtils.tx_hash()
    end
  end
end
