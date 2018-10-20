defmodule OcapRpcTest.EthTx do
  @moduledoc false

  use ExUnit.Case
  import Tesla.Mock

  alias OcapRpc.Eth.Transaction

  alias OcapRpcTest.MockHttp
  alias OcapRpcTest.TestUtils

  setup do
    mock(fn %{method: :post, body: body} ->
      json(MockHttp.post(body))
    end)

    :ok
  end

  test "Should return transaction" do
    data = Transaction.get_by_hash(TestUtils.tx_hash())
    assert data.hash == TestUtils.tx_hash()
  end

  test "Should return transaction by block number and index" do
    data = Transaction.get_by_block_number_and_index(TestUtils.block_height(), 0)
    assert data.hash == TestUtils.tx_hash()
  end

  test "Should return transaction by block hash and index" do
    data = Transaction.get_by_block_hash_and_index(TestUtils.block_hash(), 0)
    assert data.hash == TestUtils.tx_hash()
  end
end
